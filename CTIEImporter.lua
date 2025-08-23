--- CTIEImporter handles the import of character data from JSON format back into Codex game objects.
--- This class serves as the main orchestrator for the character import process, creating new Codex characters
--- and populating them with data from exported JSON files. It manages the complex process of resolving
--- lookup records, restoring feature choices, and rebuilding the hierarchical character structure
--- required by the Codex game system.
---
--- The import process involves multiple phases:
--- - JSON parsing and validation through CTIECharacterData
--- - Token-level property restoration including ownership, portraits, and display settings
--- - Character-level data import including attributes, ancestry, career, culture, and classes
--- - Feature choice resolution and application through specialized importer classes
--- - Integration with the Codex import system for final character creation
---
--- The class coordinates with specialized importers (CTIECareerImporter, CTIELevelChoiceImporter)
--- to handle complex data structures and maintains comprehensive logging throughout the process.
--- @class CTIEImporter
--- @field characterData CTIECharacterData The parsed character data from the JSON import file
--- @field t table The Codex token object being created during import
--- @field c table The Codex character properties object being populated during import
CTIEImporter = RegisterGameType("CTIEImporter")
CTIEImporter.__index = CTIEImporter

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local stringIsGuid = CTIEUtils.StringIsGuid
local STATUS = CTIEUtils.STATUS

--- Creates a new CTIEImporter instance and initializes character data from JSON text.
--- Parses the provided JSON string into a CTIECharacterData object for subsequent import operations.
--- @param jsonText string The JSON string containing exported character data
--- @return CTIEImporter instance The new importer instance with parsed character data
function CTIEImporter:new(jsonText)
    local instance = setmetatable({}, self)
    instance.characterData = CTIECharacterData:new()
    instance.characterData:FromJSON(jsonText)

    return instance
end

--- Orchestrates the complete character import process and creates the final Codex character.
--- Creates a new Codex character object, populates it with imported data through specialized
--- import methods, and integrates it into the game system via the Codex import framework.
function CTIEImporter:Import()
    writeDebug("ImportToCodex:: %s", self.characterData:GetCharacterName())
    writeLog("Codex Character Import starting.", STATUS.INFO, 1)

    self.t = import:CreateCharacter()
    self.t.properties = character.CreateNew {}
    self.c = self.t.properties

    self.t.partyId = GetDefaultPartyID()
    self.t.name = self.characterData:GetCharacterName()

    writeLog(string.format("Character Name is [%s].", self.t.name), STATUS.IMPL)

    self:_importToken()
    self:_importCharacter()

    import:ImportCharacter(self.t)

    writeLog("Codex Character Import complete.", STATUS.INFO, -1)
end

--- Imports token-level properties including display settings, ownership, and visual configuration.
--- Processes verbatim token properties, handles special cases like portraitOffset vector conversion,
--- resolves player ownership and party assignments, and ensures proper token configuration.
--- @private
function CTIEImporter:_importToken()
    writeLog("Token import starting.", STATUS.INFO, 1)

    local st = self.characterData.token
    local dt = self.t

    writeLog("Verbatim property import starting.", STATUS.INFO, 1)
    for propName, config in pairs(CTIEConfig.token.verbatim) do
        if config.import then
            writeDebug("IMPORTTOKEN:: PROP:: %s", propName)
            if type(st[propName]) == "table" then
                writeLog(string.format("Adding table property [%s].", propName), STATUS.IMPL)
                dt[propName] = DeepCopy(st[propName])
            else
                writeLog(string.format("Adding property [%s].", propName), STATUS.IMPL)
                dt[propName] = st[propName]
            end
        end
    end
    writeLog("Verbatim property import complete.", STATUS.INFO, -1)

    if st.portraitOffset then
        writeDebug("IMPORTTOKEN:: PORTRAITOFFSET:: TYPE:: %s VALUE:: %s", type(st.portraitOffset), json(st.portraitOffset))
        dt.portraitOffset = core.Vector2(st.portraitOffset.x, st.portraitOffset.y)
    end

    if st.ownerId then
        writeDebug("IMPORTTOKEN:: OWNERID:: %s", st.ownerId)
        if "PARTY" ~= st.ownerId then
            writeDebug("DMHUBUSERS:: %s %s", dmhub.users, json(dmhub.users))
            for _, id in ipairs(dmhub.users) do
                writeDebug("IMPORTTOKEN:: OWNERID:: TESTING:: %s", id)
                if id == st.ownerId then
                    writeDebug("IMPORTTOKEN:: OWNERID:: FOUND")
                    dt.ownerId = st.ownerId
                    writeLog(string.format("Setting owner to [%s].", dmhub.GetDisplayName(dt.ownerId)), STATUS.IMPL)
                    break
                end
            end
        end
    end

    if st.partyId and stringIsGuid(st.partyId) and dt.ownerId == nil then
        if CTIEUtils.TableIdExists(Party.tableName, st.partyId) then
            local partyName = dmhub.GetTable(Party.tableName)[dt.partyId].name
            dt.partyId = st.partyId
            writeLog(string.format("Setting party to [%s].", partyName), STATUS.IMPL)
        end
    end

    if not dt.partyId or #dt.partyId == 0 then
        dt.partyId = GetDefaultPartyID()
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

    local sc, dc = self:__getSourceDestCharacterAliases()

    -- Verbatim copies
    -- TODO: Does not seem necessary
    writeLog("Verbatim property import starting.", STATUS.INFO, 1)
    for propName, config in pairs(CTIEConfig.character.verbatim) do
        if config.import then
            writeDebug("IMPORTCHARACTER:: %s", propName)
            if type(sc[propName]) == "table" then
                writeLog(string.format("Adding table property [%s].", propName), STATUS.IMPL)
                local v = dc:get_or_add(propName, {})
                v = DeepCopy(sc[propName])
                writeDebug("DEEPCOPY:: %s", json(v))
            else
                writeLog(string.format("Adding property [%s].", propName), STATUS.IMPL)
                local v = dc:get_or_add(propName, sc[propName])
                v = sc[propName]
            end
        end
    end
    writeLog("Verbatim property import complete.", STATUS.INFO, -1)

    self:_importAncestry()
    self:_importCareer()
    self:_importCulture()
    self:_importClasses()
    self:_importAttributeBuild()
    self:_importAttributes()

    -- Lookup table values
    writeLog("Simple Lookup import starting.", STATUS.INFO, 1)
    for propName, tableName in pairs(CTIEConfig.character.lookupRecords) do
        local guid = CTIEUtils.ResolveLookupRecord(tableName, sc[propName])
        if guid then
            writeLog(string.format("Adding [%s].", propName), STATUS.IMPL)
            local v = dc:get_or_add(propName, guid)
            v = guid
        end
    end
    writeLog("Simple Lookup import complete.", STATUS.INFO, -1)

    writeLog("Character Import complete.", STATUS.INFO, -1)
end

--- Imports character ancestry information including race and racial feature choices.
--- Resolves race lookup records, applies racial features through the level choice system,
--- and ensures proper ancestry configuration in the destination character.
--- @private
function CTIEImporter:_importAncestry()

    local sc, dc = self:__getSourceDestCharacterAliases()

    writeDebug("IMPORTANCESTRY:: START:: %s", json(sc.ancestry))
    writeLog("Ancestry starting.", STATUS.INFO, 1)

    if sc.ancestry and sc.ancestry.raceid then
        local guid = CTIEUtils.ResolveLookupRecord(Race.tableName, sc.ancestry.raceid)
        if guid then
            writeLog(string.format("Adding ancestry %s.", sc.ancestry.raceid.name), STATUS.IMPL)
            local r = dc:get_or_add("raceid", guid)
            r = guid

            if sc.ancestry.features then
                local lcImporter = CTIELevelChoiceImporter:new(sc, dc)
                lcImporter:Import(sc.ancestry.features, dc:Race():GetClassLevel().features)
            end
        end
    end

    writeLog("Ancestry complete.", STATUS.INFO, -1)
    writeDebug("IMPORTANCESTRY:: COMPLETE:: %s", dc.raceid)
end

--- Imports character attribute build configuration data.
--- Transfers attribute build settings that control how attributes are calculated and displayed,
--- preserving the original character's attribute configuration methodology.
--- @private
function CTIEImporter:_importAttributeBuild()
    local sab = self.characterData.token.character.attributeBuild or {}
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
    local sa = self.characterData.token.character.attributes or {}
    local da = self.c:get_or_add("attributes", {})
    local s = ""

    for _, attr in ipairs(CTIEConfig.attributes) do
        da[attr].baseValue = sa[attr].baseValue
        s = string.format("%s %s %+d ", s, attr:sub(1,1):upper(), da[attr].baseValue)
    end
    writeLog(string.format("Setting Attributes [%s].", s:trim()), STATUS.IMPL)

    writeDebug("IMPORTATTRIBUTES:: %s", json(self.c.attributes))
end

--- Imports character career and background information.
--- Delegates to CTIECareerImporter to handle the complex process of background resolution,
--- inciting incident matching, and career-related feature choice restoration.
--- @private
function CTIEImporter:_importCareer()
    local sc, dc = self:__getSourceDestCharacterAliases()
    local careerImporter = CTIECareerImporter:new(sc, dc)
    careerImporter:Import()
end

--- Imports character culture information including aspects and culture-based features.
--- Resolves culture aspect lookup records, applies culture feature choices through the level
--- choice system, and ensures proper culture configuration including language selections.
--- @private
function CTIEImporter:_importCulture()

    local sc, dc = self:__getSourceDestCharacterAliases()
    local aspects = dc:get_or_add("culture", Culture.CreateNew()).aspects

    writeDebug("IMPORTCULTURE:: START:: %s", json(sc.culture.aspects))
    writeLog("Culture starting.", STATUS.INFO, 1)

    if sc.culture.features then
        local lcImporter = CTIELevelChoiceImporter:new(sc, dc)
        lcImporter:Import(sc.culture.features)
    end

    for aspectName, aspect in pairs(sc.culture.aspects) do
        writeDebug("IMPORTCULTURE:: ASPECT:: %s %s", aspectName, json(aspect))
        local aspectGuid = CTIEUtils.ResolveLookupRecord(CultureAspect.tableName, aspect)
        if aspectGuid and #aspectGuid then
            writeLog(string.format("Adding Culture Aspect [%s]->[%s].", aspectName, aspect.name), STATUS.IMPL)
            aspects[aspectName] = aspectGuid

            if aspect.features then
                local lcImporter = CTIELevelChoiceImporter:new(sc, dc)
                lcImporter:Import(aspect.features)
            end
        end
    end

    writeLog("Culture complete.", STATUS.INFO, -1)
    writeDebug("IMPORTCULTURE:: COMPLETE:: %s", json(aspects))
end

--- Imports character class information including levels and class-based feature choices.
--- Resolves class lookup records, creates class entries with appropriate levels, and applies
--- class feature choices through the level choice system for both main classes and subclasses.
--- @private
function CTIEImporter:_importClasses()
    writeDebug("IMPORTCLASSES::")
    writeLog("Class starting.", STATUS.INFO, 1)

    local sc, dc = self:__getSourceDestCharacterAliases()

    for _, classInfo in ipairs(sc.classes) do
        local classGuid = CTIEUtils.ResolveLookupRecord(Class.tableName, classInfo.classid)
        if classGuid and #classGuid then
            writeDebug("IMPORTCLASSES:: ADD:: %s %s %d", classGuid, classInfo.classid.name or "nil", classInfo.level or 1)
            writeLog(string.format("Adding Class [%s]", classInfo.classid.name), STATUS.IMPL)
            local classes = dc:get_or_add("classes", {})
            table.insert(classes, {classid = classGuid, level = classInfo.level or 1})

            writeDebug("IMPORTCLASSES:: CLASSINFO:: %s", json(classInfo))
            if classInfo.features then
                local lcImporter = CTIELevelChoiceImporter :new(sc, dc)
                lcImporter:Import(classInfo.features)
            end
        end
    end

    writeLog("Class complete.", STATUS.INFO, -1)
    writeDebug("IMPORTCLASSES:: %s", json(dc.classes))
end

--- Provides convenient aliases for source and destination character data objects.
--- Returns references to the source character data from JSON and the destination character
--- properties being populated, simplifying data access patterns throughout import methods.
--- @private
--- @return table sourceCharacter The character data from the imported JSON
--- @return table destinationCharacter The Codex character properties being populated
function CTIEImporter:__getSourceDestCharacterAliases()
    return self.characterData.token.character, self.c
end