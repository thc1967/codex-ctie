--- CTIEExporter handles the export of character data from Codex game objects to JSON format.
--- This class extracts character information including token properties, character attributes, ancestry,
--- career background, class levels, culture aspects, and feature choices, transforming them into
--- a serializable format suitable for character transfer and backup operations.
--- @class CTIEExporter
--- @field sourceToken table The source token to be exported
--- @field codexData CTIEBaseDTO|CTIECodexDTO The DTO we're writing into
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
--- @return CTIEBaseDTO|CTIECharacterDTO dto The DTO for encapsulated access
function CTIEExporter:__getSourceDestCharacterAliases()
    return self.sourceToken.properties, self.dto:Character()
end

--- Exports all character data to a CTIECodexDTO object suitable for JSON serialization.
--- Orchestrates the complete export process by calling specialized export methods for each data category.
--- Modifies character names with "zzz" prefix when in debug mode for testing purposes.
--- @return CTIEBaseDTO|CTIECodexDTO characterData The complete character data object ready for JSON export
function CTIEExporter:Export()
    self.dto = CTIECodexDTO:new()

    self:_exportToken()
    self:_exportCharacter()

    return self.dto
end

--- Exports token-level properties based on configuration settings.
--- Processes all properties listed in CTIEConfig.token.verbatim that are marked for export,
--- using deep copy for table values and direct assignment for primitive values.
--- @private
function CTIEExporter:_exportToken()
    local st = self.sourceToken

    for propName, config in pairs(CTIEConfig.token.verbatim) do
        if config.export then
            self.dto:Token():_setProp(propName, st[propName])
        end
    end
end

--- Exports character-level data and orchestrates specialized character data exports.
--- Processes verbatim character properties, lookup record conversions, and calls specialized
--- export methods for ancestry, attributes, career, classes, and culture data.
--- @private
function CTIEExporter:_exportCharacter()
    local codexToon, dto = self:__getSourceDestCharacterAliases()

    -- Verbatim transfers
    for propName, config in pairs(CTIEConfig.character.verbatim) do
        if config.export then
            dto:_setProp(propName, codexToon[propName])
        end
    end

    -- Lookup Table Keys
    for propName, config in pairs(CTIEConfig.character.lookupRecords) do
        if codexToon[config.property] and stringIsGuid(codexToon[config.property]) then
            if dto[propName] then
                local guid = codexToon:try_get(config.property)
                local name = CTIEUtils.GetRecordName(config.tableName, guid)
                dto[propName]:SetTableName(config.tableName):SetID(guid):SetName(name)
            else
                writeDebug("CTIELookupTableDTO:: ERROR:: Method %s not found!", propName)
            end
        end
    end

    self:_exportAncestry()
    self:_exportAttributes()
    self:_exportCareer()
    self:_exportClass()
    -- self:_exportCulture()
    -- TODO: Kits
end

--- Exports character ancestry information including race and racial features.
--- Extracts race data, creates lookup records for race identification, and exports
--- all race-based features and modifiers through the feature export system.
--- @private
function CTIEExporter:_exportAncestry()
    writeDebug("EXPORTANCESTRY::")
    local codexToon, dto = self:__getSourceDestCharacterAliases()

    local raceItem = codexToon:Race()
    if raceItem then
        writeDebug("EXPORTANCESTRY:: RACE:: %s, %s, %s", raceItem, codexToon:RaceID(), json(raceItem))
        local ancestry = dto:Ancestry()
        local raceId = ancestry:GuidLookup()
        raceId:SetTableName(Race.tableName):SetID(codexToon:RaceID()):SetName(raceItem.name)

        -- Set features
        local raceFill = raceItem:GetClassLevel()
        writeDebug("EXPORTANCESTRY:: RACEFILL:: %s", json(raceFill))
        if raceFill.features then
            self:_exportSelectedFeatures(raceFill.features, ancestry:SelectedFeatures())
        end

    end

    writeDebug("EXPORTANCESTRY:: %s", json(dto:Ancestry()))
end

--- Exports character attribute values and identifiers.
--- Extracts base values and IDs for all standard character attributes (might, agility, etc.)
--- as defined in CTIEConfig.attributes, preserving original attribute structure.
--- @private
function CTIEExporter:_exportAttributes()
    local codexToon, dto = self:__getSourceDestCharacterAliases()
    local sourceAttributes = codexToon.attributes or {}
    local attributesDTO = dto:Attributes()

    for _, attributeKey in ipairs(CTIEConfig.attributes) do
        local sourceAttr = sourceAttributes[attributeKey]
        if sourceAttr and sourceAttr.baseValue then
            attributesDTO:SetAttribute(attributeKey, sourceAttr.baseValue)
        end
    end
end

--- Exports character career and background information.
--- Extracts background data, searches character notes for inciting incidents,
--- and exports all background-related features through the feature export system.
--- @private
function CTIEExporter:_exportCareer()
    writeDebug("EXPORTCAREER::")
    local codexToon, dto = self:__getSourceDestCharacterAliases()

    local career = dto:Career("career")
    if career then
        local bg = codexToon:Background()
        if bg then
            writeDebug("EXPORTCAREER:: BACKGROUND:: %s %s %s", bg, codexToon:BackgroundID(), json(bg))
            local careerId = career:GuidLookup()
            if careerId then
                -- Root background information
                local guid = codexToon:try_get("backgroundid")
                local name = CTIEUtils.GetRecordName(Background.tableName, guid)
                careerId:SetTableName(Background.tableName):SetID(guid):SetName(name)

                -- Find Inciting Incident in Notes
                for _, record in pairs(codexToon.notes) do
                    if record.title and #record.title and record.title:lower() == "inciting incident" then
                        local incitingIncident = career:IncitingIncident()
                        if incitingIncident then
                            incitingIncident:SetTableName(record.tableid):SetID(record.rowid):SetName(record.text)
                        else
                            writeDebug("EXPORTCAREER:: ERROR:: incitingIncident not found on career DTO.")
                        end
                        break
                    end
                end

                -- Export the level choices
                local careerItem = dmhub.GetTable(Background.tableName)[guid]
                if careerItem then
                    local careerFill = careerItem:GetClassLevel()
                    writeDebug("EXPORTCAREER:: CAREERFILL:: %s", json(careerFill))
                    if careerFill.features then
                        self:_exportSelectedFeatures(careerFill.features, career:SelectedFeatures())
                    end
                else
                    writeDebug("EXPORTCAREER:: ERROR:: Career ID not in table.")
                end
            else
                writeDebug("EXPORTCAREER:: ERROR:: backgroundid not found on career DTO.")
            end
        end
    else
        writeDebug("EXPORTCAREER:: ERROR:: Career not found on DTO.")
    end

    writeDebug("EXPORTCAREER:: %s", json(career))
end

--- Exports selected features from features table that have matching choices in levelChoices.
--- Recursively processes nested features while maintaining flat result structure.
--- @param features table The features table to process
--- @return table result Flat table with guid keys containing typeName, source, categories, and selections
function CTIEExporter:_exportFeatures(features)
    writeDebug("EXPORTFEATURES:: START:: %s", json(features))

    local codexToon, _ = self:__getSourceDestCharacterAliases()
    local result = {}

    if not features then
        return result
    end

    for _, feature in pairs(features) do
        if feature.guid and codexToon.levelChoices[feature.guid] then
            writeDebug("EXPORTFEATURES:: MATCH:: %s %s", feature.guid, json(feature))

            -- Build selections table from levelChoices
            local selections = {}
            local tableName = CTIEUtils.ChoiceTypeToTableName(feature.typeName)

            for _, choiceGuid in pairs(codexToon.levelChoices[feature.guid]) do
                if type(choiceGuid) == "string" then -- Skip _luaTable entries
                    local selection = {
                        guid = choiceGuid,
                        tableName = tableName,
                        name = ""
                    }

                    if tableName == CTIEUtils.FEATURE_TABLE_MARKER and feature.options then
                        -- Search through options list for matching GUID
                        for _, option in pairs(feature.options) do
                            if option.guid == choiceGuid then
                                selection.name = option.name or ""
                                break
                            end
                        end
                    else
                        -- Normal table lookup
                        selection.name = CTIEUtils.GetRecordName(tableName, choiceGuid)
                    end

                    table.insert(selections, selection)
                end
            end

            -- Found matching choice in levelChoices
            local entry = {
                choiceType = feature.typeName,
                source = feature:try_get("source") or "",
                selections = selections
            }

            -- Add categories if present
            local categories = feature:try_get("categories")
            if categories then
                entry.categories = categories
            end

            -- Store with guid as key
            result[feature.guid] = entry

            -- Special handling for deity domain choices - create separate entry
            if feature.typeName == "CharacterDeityChoice" then
                local domainGuid = feature.guid .. "-domains"
                if codexToon.levelChoices[domainGuid] then
                    writeDebug("EXPORTFEATURES:: DEITY DOMAINS:: %s", domainGuid)

                    local domainSelections = {}
                    for _, choiceGuid in pairs(codexToon.levelChoices[domainGuid]) do
                        if type(choiceGuid) == "string" then
                            local domainSelection = {
                                guid = choiceGuid,
                                tableName = DeityDomain.tableName,
                                name = CTIEUtils.GetRecordName(DeityDomain.tableName, choiceGuid)
                            }
                            table.insert(domainSelections, domainSelection)
                        end
                    end

                    if #domainSelections > 0 then
                        result[domainGuid] = {
                            choiceType = "CharacterDeityDomainChoice", -- or whatever the actual type name is
                            source = feature:try_get("source") or "",
                            selections = domainSelections
                        }
                    end
                end
            end
        end

        -- Recursively process nested features, merging into flat result
        if feature:try_get("features") then
            local nestedResults = self:_exportFeatures(feature.features)
            result = CTIEUtils.MergeTables(result, nestedResults)
        end
    end

    writeDebug("EXPORTFEATURES:: COMPLETE:: %s", json(result))
    return result
end

--- Exports character class information including levels and class features.
--- Processes all character classes, extracts class levels, and exports class-specific features
--- by filling level progression data and processing both main classes and subclasses.
--- @private
function CTIEExporter:_exportClass()
    writeDebug("EXPORTCLASSES::")

    local codexToon, dto = self:__getSourceDestCharacterAliases()
    local dtoClass = dto:Class()

    -- Although the game engine supports multiclassing, the
    -- game system itself does not. Stop at the first class.
    local sourceClasses = codexToon.classes or {}
    local _, class = next(sourceClasses)
    if class then
        if type(class) == "table" and class.classid and stringIsGuid(class.classid) then

            local classGuid = dtoClass:GuidLookup()
            if classGuid then
                -- Store the lookup
                local className = CTIEUtils.GetRecordName(Class.tableName, class.classid)
                writeDebug("EXPORTCLASSES:: SETLOOKUP:: [%s] [%s] [%s]", class.classid, className, Class.tableName)
                classGuid:SetID(class.classid):SetName(className):SetTableName(Class.tableName)

                dtoClass:SetLevel(class.level)

                local c = codexToon:GetClass()
                local classFill = {}
                c:FillLevelsUpTo(dtoClass:GetLevel(), false, "nonprimary", classFill)
                writeDebug("EXPORTCLASSES:: CLASS:: %s %s", c, json(c))
                writeDebug("EXPORTCLASSES:: FILL:: %s", json(classFill))
                if classFill then
                    for _, levelFill in pairs(classFill) do
                        self:_exportSelectedFeatures(levelFill.features, dtoClass:SelectedFeatures())
                    end
                end

                local subclasses = codexToon:GetSubclasses()
                local _, subclass = next(subclasses)
                if subclass then
                    classFill = {}
                    subclass:FillLevelsUpTo(dtoClass:GetLevel(), false, "nonprimary", classFill)
                    writeDebug("EXPORTCLASS:: SUBCLASS:: %s %s", subclass, json(subclass))
                    writeDebug("EXPORTCLASS:: SUBCLASS:: FILL:: %s", json(classFill))
                    if classFill then
                        for _, levelFill in pairs(classFill) do
                            self:_exportSelectedFeatures(levelFill.features, dtoClass:SelectedFeatures())
                        end
                    end
                end

            end
        end
    end

    writeDebug("EXPORTCLASSES:: %s", json(dtoClass))
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
            culture.aspects[aspectName] = CTIEUtils.MakeLookupRecord(CultureAspect.tableName,
                sc.culture.aspects[aspectName])

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
            cultureLanguageChoice = { CTIEUtils.MakeLookupRecord(Language.tableName, sc.levelChoices.cultureLanguageChoice[1]) }
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
function CTIEExporter:_exportFeaturesOld(featureList)
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
                            self:_addDeityDomains(feature.guid, sc, features) -- Pass features instead of selections
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

--- Exports features and populates target DTO with selected feature data.
--- Combines _exportFeatures() and _populateSelectedFeatures() into single operation.
--- @param features table The features table to process  
--- @param target CTIESelectedFeaturesDTO The container to populate with selected features
function CTIEExporter:_exportSelectedFeatures(features, target)
    self:_populateSelectedFeatures(self:_exportFeatures(features), target)
end

--- Handles the special case of deity domain selections for deity choice features.
--- Extracts domain choices associated with deity selections and adds them as separate feature entries
--- in the main features table rather than nesting them within the deity selection.
--- @private
--- @param featureGuid string The GUID of the deity choice feature
--- @param sourceCharacter table The source character data containing level choices
--- @param features table The main features table to add domain selections to
function CTIEExporter:_addDeityDomains(featureGuid, sourceCharacter, features) -- Changed parameter name
    local domainGuid = featureGuid .. "-domains"
    local domainChoices = sourceCharacter.levelChoices[domainGuid]
    if domainChoices then
        local domainSelections = {}
        for _, domainItem in pairs(domainChoices) do
            local domainSelection = CTIEUtils.MakeLookupRecord(DeityDomain.tableName, domainItem)
            if next(domainSelection) then
                table.insert(domainSelections, domainSelection) -- Add to separate array
            end
        end
        if next(domainSelections) then
            features[domainGuid] = domainSelections -- Add as separate feature
        end
    end
end

--- Populates a CTIESelectedFeaturesDTO with processed feature data.
--- Converts exported feature data into SelectedFeatureDTO objects with LookupTableDTO selections.
--- @param features table The features table returned from _exportFeatures()
--- @param targetSelectedFeatures CTIESelectedFeaturesDTO The container to populate with selected features
function CTIEExporter:_populateSelectedFeatures(features, targetSelectedFeatures)
    for featureGuid, featureData in pairs(features) do
        local selectedFeature = CTIESelectedFeatureDTO:new()
            :SetChoiceId(featureGuid)
            :SetSource(featureData.source or "")
            :SetChoiceType(featureData.choiceType)

        if featureData.categories then
            selectedFeature:SetCategories(featureData.categories)
        end

        for _, selection in pairs(featureData.selections) do
            local lookupDTO = CTIELookupTableDTO:new()
                :SetTableName(selection.tableName)
                :SetID(selection.guid)
                :SetName(selection.name)
            selectedFeature:AddSelection(lookupDTO)
        end

        targetSelectedFeatures:AddFeature(selectedFeature)
    end
end
