--- CTIEImporter handles the import of character data from JSON format back into Codex game objects.
--- This class serves as the main orchestrator for the character import process, creating new Codex characters
--- and populating them with data from exported JSON files. It manages the complex process of resolving
--- lookup records, restoring feature choices, and rebuilding the hierarchical character structure
--- required by the Codex game system.
---
--- The import process involves multiple phases:
--- - JSON parsing and validation through CTIECodexDTO
--- - Token-level property restoration including ownership, portraits, and display settings
--- - Character-level data import including attributes, ancestry, career, culture, and classes
--- - Feature choice resolution and application through specialized importer classes
--- - Integration with the Codex import system for final character creation
---
--- The class coordinates with specialized importers (CTIECareerImporter, CTIELevelChoiceImporter)
--- to handle complex data structures and maintains comprehensive logging throughout the process.
--- @class CTIEImporter
--- @field dto CTIECodexDTO The parsed character data from the JSON import file
--- @field t table The Codex token object being created during import
--- @field c table The Codex character properties object being populated during import
CTIEImporter = RegisterGameType("CTIEImporter")
CTIEImporter.__index = CTIEImporter

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local fileLogger = CTIEUtils.FileLogger
local STATUS = CTIEUtils.STATUS

--- Creates a new CTIEImporter instance with pre-populated character data.
--- Takes a populated CTIECodexDTO object for import operations, eliminating the JSON parsing
--- responsibility from the importer and allowing for programmatic character data construction.
--- @param dto CTIECodexDTO The populated character data object for import
--- @return CTIEImporter instance The new importer instance with character data
function CTIEImporter:new(dto)
    local instance = setmetatable({}, self)
    instance.dto = dto
    return instance
end

--- Provides convenient aliases for source and destination character data objects.
--- Returns references to the source character data from JSON and the destination character
--- properties being populated, simplifying data access patterns throughout import methods.
--- @private
--- @return CTIEBaseDTO|CTIECharacterDTO dto The character data DTO for encapsulated access
--- @return table codexToon The Codex character properties being populated
function CTIEImporter:__getSourceDestCharacterAliases()
    return self.dto:Character(), self.c
end

--- Orchestrates the complete character import process and creates the final Codex character.
--- Creates a new Codex character object, populates it with imported data through specialized
--- import methods, and integrates it into the game system via the Codex import framework.
function CTIEImporter:Import()
    writeDebug("IMPORT:: %s", json(self.dto))
    local dto = self.dto

    writeDebug("ImportToCodex:: %s", dto:GetCharacterName())
    writeLog("Codex Character Import starting.", STATUS.INFO, 1)

    self.t = import:CreateCharacter()
    self.t.properties = character.CreateNew {}
    self.c = self.t.properties

    self.t.partyId = GetDefaultPartyID()
    self.t.name = (CTIEUtils.inDebugMode() and "zzz" or "") .. dto:GetCharacterName()

    writeLog(string.format("Character Name is [%s].", self.t.name), STATUS.IMPL)
    writeLog(string.format("Career Background Name is [%s].", dto:Character():Career():GuidLookup().name))

    -- Move values into the Codex token & character objects
    self:_importToken()
    self:_importCharacter()

    -- Execute the Codex import
    import:ImportCharacter(self.t)

    writeLog("Codex Character Import complete.", STATUS.INFO, -1)
end

--- Imports token-level properties including display settings, ownership, and visual configuration.
--- Processes verbatim token properties, handles special cases like portraitOffset vector conversion,
--- resolves player ownership and party assignments, and ensures proper token configuration.
--- @private
function CTIEImporter:_importToken()
    writeLog("Token import starting.", STATUS.INFO, 1)

    local dtoToken = self.dto:Token()
    local codexToken = self.t

    writeLog("Verbatim property import starting.", STATUS.INFO, 1)
    for propName, config in pairs(CTIEConfig.token.verbatim) do
        if config.import then
            local value = dtoToken:_getProp(propName)
            if value then
                writeDebug("IMPORTTOKEN:: PROP:: %s", propName)
                writeLog(string.format("Adding property [%s].", propName), STATUS.IMPL)
                codexToken[propName] = value
            end
        end
    end
    writeLog("Verbatim property import complete.", STATUS.INFO, -1)

    local offset = dtoToken:_getProp("portraitOffset")
    if offset then
        writeDebug("IMPORTTOKEN:: PORTRAITOFFSET:: TYPE:: %s VALUE:: %s", type(offset), json(offset))
        codexToken.portraitOffset = core.Vector2(offset.x, offset.y)
        writeLog("Adding property [portraitOffset].", STATUS.IMPL)
    end

    local ownerId = dtoToken:_getProp("ownerId")
    if ownerId then
        writeDebug("IMPORTTOKEN:: OWNERID:: %s", ownerId)
        if "PARTY" ~= ownerId then
            writeDebug("DMHUBUSERS:: %s %s", dmhub.users, json(dmhub.users))
            for _, id in ipairs(dmhub.users) do
                writeDebug("IMPORTTOKEN:: OWNERID:: TESTING:: %s", id)
                if id == ownerId then
                    writeDebug("IMPORTTOKEN:: OWNERID:: FOUND")
                    codexToken.ownerId = ownerId
                    writeLog(string.format("Setting owner to [%s].", dmhub.GetDisplayName(codexToken.ownerId)), STATUS.IMPL)
                    break
                end
            end
        end
    else
        -- No owner; try to set the Party
        local partyId = dtoToken:_getProp("partyId")
        local partyName = CTIEUtils:GetRecordName(Party.tableName, partyId)
        if partyName and #partyName then
            codexToken.partyId = partyId
            writeLog(string.format("Setting party to [%s].", partyName), STATUS.IMPL)
        end
    end

    if not codexToken.partyId or #codexToken.partyId == 0 then
        codexToken.partyId = GetDefaultPartyID()
        writeLog("Setting party to default.", STATUS.IMPL)
    end

    writeLog("Token import complete.", STATUS.INFO, -1)
end

--- Imports character-level data and orchestrates specialized character data import operations.
--- Processes verbatim character properties and coordinates with specialized importers for
--- ancestry, career, culture, classes, attributes, and lookup record resolution.
--- @private
function CTIEImporter:_importCharacter()
    writeLog("Character Import starting.", STATUS.INFO, 1)

    local dto, codexToon = self:__getSourceDestCharacterAliases()

    -- self:_importAncestry()
    self:_importCareer()
    -- self:_importCulture()
    self:_importClass()
    -- self:_importAttributeBuild()
    -- self:_importAttributes()

    -- Lookup table values
    writeLog("Simple Lookup import starting.", STATUS.INFO, 1)
    for propName, config in pairs(CTIEConfig.character.lookupRecords) do
        local r = dto:_getProp(propName)
        writeDebug("IMPORTCHARACTER:: SIMPLELOOKUP:: %s -> %s", propName, json(r))
        if r then
            local guid = CTIEUtils.ResolveLookupRecord(config.tableName, r.name, r.guid)
            if guid then
                writeLog(string.format("Adding [%s]->[%s].", propName, r.name), STATUS.IMPL)
                local v = codexToon:get_or_add(propName, guid)
                v = guid
            end
        end
    end
    writeLog("Simple Lookup import complete.", STATUS.INFO, -1)

    -- Verbatim copies
    writeLog("Verbatim property import starting.", STATUS.INFO, 1)
    for propName, config in pairs(CTIEConfig.character.verbatim) do
        if config.import then
            local value = dto:_getProp(propName)
            writeDebug("IMPORTCHARACTER:: VERBATIM:: %s -> %s", propName, json(value))
            if value then
                writeDebug("IMPORTCHARACTER:: VERBATIM:: %s", propName)
                writeLog(string.format("Adding property [%s].", propName), STATUS.IMPL)
                local v = codexToon:get_or_add(propName, {})
                if config.keyed then
                    v = CTIEUtils.MergeTables(v, value)
                else
                    v = CTIEUtils.AppendList(v, value)
                end
            end
        end
    end
    writeLog("Verbatim property import complete.", STATUS.INFO, -1)

    writeLog("Character Import complete.", STATUS.INFO, -1)
end

--- Imports character ancestry information including race and racial feature choices.
--- Resolves race lookup records, applies racial features through the level choice system,
--- and ensures proper ancestry configuration in the destination character.
--- @private
function CTIEImporter:_importAncestry()

    local sc, dc = self:__getSourceDestCharacterAliases()

    writeDebug("IMPORTANCESTRY:: START:: %s", json(sc:GetAncestry()))
    writeLog("Ancestry starting.", STATUS.INFO, 1)

    local ancestry = sc:GetAncestry()
    if ancestry and ancestry.raceid then
        local guid = CTIEUtils.ResolveLookupRecord(Race.tableName, ancestry.raceid.name, ancestry.raceid.guid)
        if guid then
            writeLog(string.format("Adding ancestry %s.", ancestry.raceid.name), STATUS.IMPL)
            local r = dc:get_or_add("raceid", guid)
            r = guid

            local lcImporter = CTIELevelChoiceImporter:new(dc)
            local raceFill = dc:Race():GetClassLevel().features
            if ancestry.features then
                lcImporter:Import(ancestry.features, raceFill)
            end
            if ancestry.unkeyedFeatures then
                lcImporter:ImportUnkeyed(ancestry.unkeyedFeatures, raceFill)
            end
        end
    end

    writeLog("Ancestry complete.", STATUS.INFO, -1)
    writeDebug("IMPORTANCESTRY:: COMPLETE:: %s", dc:try_get("raceid"))
end

--- Imports character attribute build configuration data.
--- Transfers attribute build settings that control how attributes are calculated and displayed,
--- preserving the original character's attribute configuration methodology.
--- @private
function CTIEImporter:_importAttributeBuild()
    local sab = self.characterData:GetCharacterProperty("attributeBuild") or {}
    local dab = self.c:get_or_add("attributeBuild", {})

    for k, v in pairs(sab) do
        dab[k] = v
    end

    writeDebug("IMPORTATTRIBUTEBUILD:: %s", json(self.c.attributeBuild))
end

--- Imports character attribute base values for all standard attributes.
--- Sets the base values for might, agility, intuition, presence, and reason attributes
--- as defined in the exported character data, with logging of the final attribute spread.
--- @private
function CTIEImporter:_importAttributes()
    local sc = self.characterData
    local sourceAttributes = sc:GetAttributes()
    local destinationAttributes = self.c:get_or_add("attributes", {})

    for _, attr in ipairs(CTIEConfig.attributes) do
        if sourceAttributes[attr] then
            destinationAttributes[attr].baseValue = sourceAttributes[attr].baseValue
        end
    end

    writeLog(string.format("Setting Attributes [%s].", sc:GetAttributesSummary()), STATUS.IMPL)

    writeDebug("IMPORTATTRIBUTES:: %s", json(self.c.attributes))
end

--- Imports character career and background information.
--- Delegates to CTIECareerImporter to handle the complex process of background resolution,
--- inciting incident matching, and career-related feature choice restoration.
--- @private
function CTIEImporter:_importCareer()
    local sc, dc = self:__getSourceDestCharacterAliases() --TODO:
    local careerImporter = CTIECareerImporter:new(self:__getSourceDestCharacterAliases())
    careerImporter:Import()
end

--- Processes class features for a given class or subclass object.
--- @param classObject table The class or subclass object to process
--- @param selectedFeatures CTIESelectedFeaturesDTO The selected features to import
--- @param level number The level to fill up to
--- @param codexToon table The destination character object
--- @private
function CTIEImporter:_processClassFeatures(classObject, selectedFeatures, level, codexToon)
    local classFill = {}
    classObject:FillLevelsUpTo(level, false, "nonprimary", classFill)

    if classFill then
        fileLogger("import"):Log("PROCESSCLASSFEATURES:: SELECTED::\n%s", json(selectedFeatures))
        fileLogger("import"):Log("PROCESSCLASSFEATURES:: CLASSFILL::\n%s", json(classFill))
        for _, levelFill in pairs(classFill) do
            local levelChoices = CTIELevelChoiceImporter:new(selectedFeatures, levelFill.features)
            if next(levelChoices) then
                local lc = codexToon:GetLevelChoices()
                CTIEUtils.MergeTables(lc, levelChoices)
            end
        end
    end
end

--- Imports character class information including levels and class-based feature choices.
--- Resolves class lookup records, creates class entries with appropriate levels, and applies
--- class feature choices through the level choice system for both main classes and subclasses.
--- @private
function CTIEImporter:_importClass()
    writeDebug("IMPORTCLASS::")
    fileLogger("import"):Log("IMPORTCLASS::"):Indent()
    writeLog("Class starting.", STATUS.INFO, 1)

    local dto, codexToon = self:__getSourceDestCharacterAliases()
    local dtoClass = dto:Class()

    if dtoClass then
        local classGuid = CTIEUtils.ResolveLookupRecord(Class.tableName, dtoClass:GuidLookup():GetName(), dtoClass:GuidLookup():GetID())
        if classGuid and #classGuid then
            writeDebug("IMPORTCLASS:: ADD:: %s %s %d", classGuid, dtoClass:GuidLookup():GetName() or "nil", dtoClass:GetLevel())
            writeLog(string.format("Adding Class [%s]", dtoClass:GuidLookup():GetName()), STATUS.IMPL)
            local classes = codexToon:get_or_add("classes", {})
            table.insert(classes, {classid = classGuid, level = dtoClass:GetLevel() or 1})

            -- Process selected features
            local selectedFeatures = dtoClass:SelectedFeatures()
            if selectedFeatures then
                local classInfo = codexToon:GetClass()
                fileLogger("import"):Log("PROCESSFEATURES:: CLASS::"):Indent()
                self:_processClassFeatures(classInfo, selectedFeatures, dtoClass:GetLevel(), codexToon)
                fileLogger("import"):Outdent():Log("PROCESSFEATURES:: CLASS:: COMPLETE::")

                -- Process selected subclass features
                local subclasses = codexToon:GetSubclasses()
                local _, subclass = next(subclasses)
                if subclass then
                    fileLogger("import"):Log("PROCESSFEATURES:: SUBCLASS::"):Indent()
                    self:_processClassFeatures(subclass, selectedFeatures, dtoClass:GetLevel(), codexToon)
                    fileLogger("import"):Outdent():Log("PROCESSFEATURES:: SUBCLASS:: COMPLETE::")
                end
            end

            -- Process domains, if any
            local domains = codexToon:GetDomains()
            writeDebug("IMPORTCLASS:: DOMAINS:: %s", json(domains))
            -- if domains and next(domains) then
            --     for _, deityDomain in pairs(domains) do
            --         self:_processClassFeatures(deityDomain, selectedFeatures, dtoClass:GetLevel(), codexToon)
            --     end
            -- end
        end
    end

    writeLog("Class complete.", STATUS.INFO, -1)
    fileLogger("import"):Outdent():Log("IMPORTCLASS:: COMPLETE::")
    writeDebug("IMPORTCLASS:: COMPLETE:: %s", json(codexToon:try_get("classes")))
end

--- Imports character culture information including aspects and culture-based features.
--- Resolves culture aspect lookup records, applies culture feature choices through the level
--- choice system, and ensures proper culture configuration including language selections.
--- @private
function CTIEImporter:_importCulture()

    local sc, dc = self:__getSourceDestCharacterAliases()
    local culture = sc:GetCulture()
    local aspects = dc:get_or_add("culture", Culture.CreateNew()).aspects

    writeDebug("IMPORTCULTURE:: START:: %s", json(culture and culture.aspects))
    writeLog("Culture starting.", STATUS.INFO, 1)

    if culture and culture.features then
        local lcImporter = CTIELevelChoiceImporter:new(dc)
        lcImporter:Import(culture.features)
    end

    if culture and culture.aspects then
        for aspectName, aspect in pairs(culture.aspects) do
            writeDebug("IMPORTCULTURE:: ASPECT:: %s %s", aspectName, json(aspect))
            local aspectGuid = CTIEUtils.ResolveLookupRecord(CultureAspect.tableName, aspect.name, aspect.guid)
            if aspectGuid and #aspectGuid then
                writeLog(string.format("Adding Culture Aspect [%s]->[%s].", aspectName, aspect.name), STATUS.IMPL)
                aspects[aspectName] = aspectGuid

                local lcImporter = CTIELevelChoiceImporter:new(dc)
                if aspect.features then
                    lcImporter:Import(aspect.features)
                end
                if aspect.unkeyedFeatures then
                    local aspectFill = dmhub.GetTable(CultureAspect.tableName)[aspectGuid]:GetClassLevel()
                    lcImporter:ImportUnkeyed(aspect.unkeyedFeatures, aspectFill.features)
                end
            end
        end
    end

    writeLog("Culture complete.", STATUS.INFO, -1)
    writeDebug("IMPORTCULTURE:: COMPLETE:: %s", json(aspects))
end