--- CTIEExporter handles the export of character data from Codex game objects to JSON format.
--- This class extracts character information including token properties, character attributes, ancestry,
--- career background, class levels, culture aspects, and feature choices, transforming them into
--- a serializable format suitable for character transfer and backup operations.
--- @class CTIEExporter
--- @field sourceToken table The source token to be exported
CTIEExporter = RegisterGameType("CTIEExporter")
CTIEExporter.__index = CTIEExporter

local writeDebug = CTIEUtils.writeDebug
local stringIsGuid = CTIEUtils.StringIsGuid

--- Creates a new CTIEExporter instance for the specified token.
--- Validates that the provided token is a valid hero character before creating the exporter instance.
--- Returns nil if the token is invalid, missing properties, or not a hero character.
--- @param token table The Codex token object to export (must have properties and be a hero)
--- @return CTIEExporter|nil instance The new exporter instance if valid, nil if token validation fails
function CTIEExporter:new(token)
    if not token or not token.properties or not token.properties:IsHero() then
        return nil
    end
    local instance = setmetatable({}, self)
    instance.sourceToken = token
    return instance
end

--- Provides convenient aliases for source and destination character data objects.
--- Returns references to the source token properties and destination character data
--- to simplify data access patterns throughout the export process.
--- @private
--- @return table sourceCharacter The source token's properties object
--- @return CTIECharacterData characterData The character data DTO for encapsulated access
function CTIEExporter:__getSourceDestCharacterAliases()
    return self.sourceToken.properties, self.characterData
end

--- Exports all character data to a CTIECharacterData object suitable for JSON serialization.
--- Orchestrates the complete export process by calling specialized export methods for each data category.
--- Modifies character names with "zzz" prefix when in debug mode for testing purposes.
--- @return CTIECharacterData characterData The complete character data object ready for JSON export
function CTIEExporter:Export()
    self.characterData = CTIECharacterData:new()

    self:_exportToken()
    self:_exportCharacter()

    if CTIEUtils:inDebugMode() then 
        self.characterData:SetCharacterName("zzz" .. self.characterData:GetCharacterName())
    end

    return self.characterData
end

--- Exports token-level properties based on configuration settings.
--- Processes all properties listed in CTIEConfig.token.verbatim that are marked for export,
--- using deep copy for table values and direct assignment for primitive values.
--- @private
function CTIEExporter:_exportToken()
    local st = self.sourceToken

    for propName, config in pairs(CTIEConfig.token.verbatim) do
        if config.export then
            self.characterData:SetTokenProperty(propName, st[propName])
        end
    end
end

--- Exports character-level data and orchestrates specialized character data exports.
--- Processes verbatim character properties, lookup record conversions, and calls specialized
--- export methods for ancestry, attributes, career, classes, and culture data.
--- @private
function CTIEExporter:_exportCharacter()

    local sc, dc = self:__getSourceDestCharacterAliases()

    -- Verbatim transfers
    for propName, config in pairs(CTIEConfig.character.verbatim) do
        if config.export then
            dc:SetCharacterProperty(propName, sc[propName])
        end
    end

    -- Lookup Table Keys  
    for propName, tableName in pairs(CTIEConfig.character.lookupRecords) do
        if sc[propName] and stringIsGuid(sc[propName]) then
            dc:SetLookupRecord(propName, CTIEUtils.MakeLookupRecord(tableName, sc[propName]))
        end
    end

    self:_exportAncestry()
    self:_exportAttributes()
    self:_exportCareer()
    self:_exportClasses()
    self:_exportCulture()

end

--- Exports character ancestry information including race and racial features.
--- Extracts race data, creates lookup records for race identification, and exports
--- all race-based features and modifiers through the feature export system.
--- @private
function CTIEExporter:_exportAncestry()
    writeDebug("EXPORTANCESTRY::")
    local sc, dc = self:__getSourceDestCharacterAliases()
    local a = {
        features = {},
    }

    local r = sc:Race()
    if r then
        writeDebug("EXPORTANCESTRY:: RACE:: %s, %s, %s", r, sc:RaceID(), json(r))
        a.raceid = CTIEUtils.CreateLookupRecord(Race.tableName, r.id, r.name)
        a.features = self:_exportFeatures(r.modifierInfo.features)
    end

    dc:SetAncestry(a)
    writeDebug("EXPORTANCESTRY:: %s", json(a))
end

--- Exports character attribute values and identifiers.
--- Extracts base values and IDs for all standard character attributes (might, agility, etc.)
--- as defined in CTIEConfig.attributes, preserving original attribute structure.
--- @private
function CTIEExporter:_exportAttributes()
    self.characterData:SetAttributes(self.sourceToken.properties.attributes)
end

--- Exports character career and background information.
--- Extracts background data, searches character notes for inciting incidents,
--- and exports all background-related features through the feature export system.
--- @private
function CTIEExporter:_exportCareer()
    writeDebug("EXPORTCAREER::")
    local sc, dc = self:__getSourceDestCharacterAliases()
    local b = {}

    local bg = sc:Background()
    if bg then
        writeDebug("EXPORTCAREER:: BACKGROUND:: %s %s %s", bg, sc:BackgroundID(), json(bg))
        b.backgroundid = CTIEUtils.CreateLookupRecord(Background.tableName, bg.id, bg.name)

        -- Find Inciting Incident in Notes
        for _, record in pairs(sc.notes) do
            if record.title and #record.title and record.title:lower() == "inciting incident" then
                b.incitingIncident = record
                break
            end
        end

        -- Export feature choices made
        b.features = self:_exportFeatures(bg.modifierInfo.features)
    end

    dc:SetCareer(b)
    writeDebug("EXPORTCAREER:: %s", json(b))
end

--- Exports character class information including levels and class features.
--- Processes all character classes, extracts class levels, and exports class-specific features
--- by filling level progression data and processing both main classes and subclasses.
--- @private
function CTIEExporter:_exportClasses()
    writeDebug("EXPORTCLASSES::")

    local sc, dc = self:__getSourceDestCharacterAliases()

    local classes = {}

    local sourceClasses = sc.classes or {}
    for _, class in pairs(sourceClasses) do
        -- Skip the _luaTable marker
        if type(class) == "table" then
            local classData = {}

            -- Use MakeLookupRecord for classid
            if class.classid and stringIsGuid(class.classid) then
                classData.classid = CTIEUtils.MakeLookupRecord(Class.tableName, class.classid)
            end
            classData.level = class.level or 1

            local c = sc:GetClass()
            local f = {}
            c:FillLevelsUpTo(classData.level, false, "nonprimary", f)
            writeDebug("EXPORTCLASSES:: CLASS:: %s %s", c, json(c))
            writeDebug("EXPORTCLASSES:: FILL:: %s", json(f))

            classData.features = {}
            for _, item in pairs(f) do
                if next(item.features) then
                    classData.features = CTIEUtils.MergeTables(classData.features, self:_exportFeatures(item.features))
                end
            end

            local subclasses = sc:GetSubclasses()
            for _, subclass in pairs(subclasses) do
                f = {}
                subclass:FillLevelsUpTo(classData.level, false, "nonprimary", f)
                writeDebug("EXPORTCLASSES:: SUBCLASS:: %s %s", subclass, json(subclass))
                writeDebug("EXPORTCLASSES:: SUBCLASS:: FILL:: %s", json(f))
                for _, item in pairs(f) do
                    if next(item.features) then
                        classData.features = CTIEUtils.MergeTables(classData.features, self:_exportFeatures(item.features))
                    end
                end
            end

            table.insert(classes, classData)
        end
    end

    dc:SetClasses(classes)
    writeDebug("EXPORTCLASSES:: %s", json(dc:GetClasses()))
end

--- Exports character culture information including aspects and language choices.
--- Processes culture aspects (environment, organization, upbringing), extracts culture-based features,
--- and handles special culture language choice selections through the level choice system.
--- @private
function CTIEExporter:_exportCulture()

    local sc, dc = self:__getSourceDestCharacterAliases()
    local culture = {
        aspects = {},
    }
    writeDebug("EXPORTCULTURE:: START:: %s", json(sc.culture))

    local function exportCultureAspect(aspectName)
        if stringIsGuid(sc.culture.aspects[aspectName]) then
            culture.aspects[aspectName] = CTIEUtils.MakeLookupRecord(CultureAspect.tableName, sc.culture.aspects[aspectName])

            local caItem = dmhub.GetTable(CultureAspect.tableName)[sc.culture.aspects[aspectName]]
            if caItem then
                writeDebug("EXPORTCULTURE:: CULTUREASPECT:: %s %s", caItem, json(caItem))
                local fill = caItem:GetClassLevel();
                writeDebug("EXPORTCULTURE:: CULTUREASPECT:: FILL:: %s", json(fill))
                culture.aspects[aspectName].features = self:_exportFeatures(caItem:GetClassLevel().features)
            end
        end
    end

    if sc.levelChoices and sc.levelChoices.cultureLanguageChoice then
        culture.features = {
            cultureLanguageChoice = { CTIEUtils.MakeLookupRecord(Language.tableName, sc.levelChoices.cultureLanguageChoice[1])}
        }
    end

    if sc.culture and type(sc.culture) == "table" and sc.culture.aspects and type(sc.culture.aspects) == "table" then
        exportCultureAspect("environment")
        exportCultureAspect("organization")
        exportCultureAspect("upbringing")
    end

    dc:SetCulture(culture)

    writeDebug("EXPORTCULTURE:: END:: %s", json(dc:GetCulture()))
end

--- Recursively exports feature data and choice selections across all feature types.
--- Handles feature choices by type (skills, languages, deities, feats, etc.), processes nested features,
--- and manages special cases like deity domain selections. Supports recursive processing for complex feature hierarchies.
--- @private
--- @param featureList table The list of features to process and export
--- @return table features The exported feature data organized by feature GUID
function CTIEExporter:_exportFeatures(featureList)
    writeDebug("EXPORTFEATURES:: START:: %s", json(featureList))

    local sc, _ = self:__getSourceDestCharacterAliases()
    local features = {}

    for _, feature in pairs(featureList) do
        writeDebug("EXPORTFEATURES:: FEATURE:: %s %s", feature.typeName, json(feature))

        local typeName = feature.typeName:lower()
        if typeName:sub(-6) == "choice" then
            if sc.levelChoices[feature.guid] then
                local selections = {}
                -- Find it in the choices list
                for _, item in pairs(sc.levelChoices[feature.guid]) do
                    local selection = {}
                    if typeName:find("skill") then
                        selection = CTIEUtils.MakeLookupRecord(Skill.tableName, item)
                    elseif typeName:find("language") then
                        selection = CTIEUtils.MakeLookupRecord(Language.tableName, item)
                    elseif typeName:find("subclass") then
                        selection = CTIEUtils.MakeLookupRecord("subclasses", item)
                    elseif typeName:find("deity") then
                        selection = CTIEUtils.MakeLookupRecord(Deity.tableName, item)
                        if next(selection) then
                            self:_addDeityDomains(feature.guid, sc, features)  -- Pass features instead of selections
                        end
                    elseif typeName:find("feature") then
                        selection = CTIEUtils.MakeFeatureRecord(feature.options, item)
                    elseif typeName:find("feat") then
                        selection = CTIEUtils.MakeLookupRecord(CharacterFeat.tableName, item)
                    end
                    if next(selection) then table.insert(selections, selection) end
                end

                if next(selections) then features[feature.guid] = selections end
            end
        elseif typeName == "classlevel" or typeName == "characterfeaturelist" then
            -- Handle nested features
            if feature:try_get("features") and next(feature.features) then
                local nestedFeatures = self:_exportFeatures(feature.features)
                -- Merge nested results into main features table
                for guid, selections in pairs(nestedFeatures) do
                    features[guid] = selections
                end
            end
        end
    end

    writeDebug("EXPORTFEATURES:: %s", json(features))
    return features
end

--- Handles the special case of deity domain selections for deity choice features.
--- Extracts domain choices associated with deity selections and adds them as separate feature entries
--- in the main features table rather than nesting them within the deity selection.
--- @private
--- @param featureGuid string The GUID of the deity choice feature
--- @param sourceCharacter table The source character data containing level choices
--- @param features table The main features table to add domain selections to
function CTIEExporter:_addDeityDomains(featureGuid, sourceCharacter, features)  -- Changed parameter name
    local domainGuid = featureGuid .. "-domains"
    local domainChoices = sourceCharacter.levelChoices[domainGuid]
    if domainChoices then
        local domainSelections = {}
        for _, domainItem in pairs(domainChoices) do
            local domainSelection = CTIEUtils.MakeLookupRecord(DeityDomain.tableName, domainItem)
            if next(domainSelection) then
                table.insert(domainSelections, domainSelection)  -- Add to separate array
            end
        end
        if next(domainSelections) then
            features[domainGuid] = domainSelections  -- Add as separate feature
        end
    end
end
