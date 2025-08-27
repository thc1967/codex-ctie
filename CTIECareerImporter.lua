--- CTIECareerImporter handles the import of career-related character data from exported JSON files.
--- This class processes background information, inciting incidents, and associated level choices,
--- translating them back into the Codex game system format during character import operations.
--- @class CTIECareerImporter
--- @field dto CTIEBaseDTO|CTIECharacterDTO The character data DTO containing career information
--- @field codexToon table The destination character object in the Codex system
CTIECareerImporter = RegisterGameType("CTIECareerImporter")
CTIECareerImporter.__index = CTIECareerImporter

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Creates a new CTIECareerImporter instance for importing career data.
--- @param dto CTIEBaseDTO|CTIECharacterDTO The source character data from the exported JSON file
--- @param codexToon table The destination character object in the Codex system
--- @return CTIECareerImporter instance The new importer instance
function CTIECareerImporter:new(dto, codexToon)
    local instance = setmetatable({}, self)
    instance.dto = dto
    instance.codexToon = codexToon
    return instance
end

--- Imports all career-related data from the source character to the destination character.
--- Processes background information, inciting incidents, and level choice features if present.
--- Logs import progress and delegates to specialized importers as needed.
function CTIECareerImporter:Import()
    writeDebug("IMPORTCAREER::")
    writeLog("Career starting.", STATUS.INFO, 1)

    local career = self.dto:Career()
    if career then
        local guidLookup = career:GuidLookup()
        if guidLookup then
            local careerGuid = self:_importCareer(guidLookup)
            if careerGuid then

                if career.incitingIncident then
                    self:_importIncitingIncident(career, careerGuid)
                end

                local selectedFeatures = career:SelectedFeatures()
                if selectedFeatures then
                    local levelFill = dmhub.GetTable(Background.tableName)[careerGuid]:GetClassLevel()
                    if levelFill and levelFill.features then
                        local levelChoices = CTIELevelChoiceImporter:new(selectedFeatures, levelFill.features)
                        writeDebug("IMPORTCAREER:: LEVELCHOICES:: %s", json(levelChoices))
                        if next(levelChoices) then
                            local lc = self.codexToon:GetLevelChoices()
                            CTIEUtils.MergeTables(lc, levelChoices)
                        end
                    end
                end
            end
        end
    end

    writeLog("Career complete.", STATUS.INFO, -1)
end

--- Imports and resolves the character's background from exported lookup record data.
--- Uses CTIEUtils.ResolveLookupRecord to match the background by GUID or name and assigns it to the destination character.
--- @private
--- @param guidLookup CTIEBaseDTO|CTIELookupTableDTO The background lookup record containing tableName, guid, and name
--- @return string|nil guid The resolved background GUID if successful, nil if failed
function CTIECareerImporter:_importCareer(guidLookup)
    local guid = CTIEUtils.ResolveLookupRecord(Background.tableName, guidLookup:GetName(), guidLookup:GetID())
    if guid then
        writeLog(string.format("Adding Career [%s]", guidLookup:GetName()), STATUS.IMPL)
        self.codexToon:get_or_add("backgroundid", guid)
    end
    return guid
end

--- Imports the character's inciting incident by matching it against background characteristics.
--- Searches through the background's characteristics to find matching inciting incident entries,
--- either by row ID or by fuzzy name matching, then adds the result as a character note.
--- @private
--- @param career CTIECareerDTO|CTIEBaseDTO The career data containing inciting incident information
--- @param careerGuid string The resolved GUID of the character's background
function CTIECareerImporter:_importIncitingIncident(career, careerGuid)
    writeLog("Inciting Incident starting.", STATUS.INFO, 1)

    local careerItem = dmhub.GetTable(Background.tableName)[careerGuid]
    local incidentNote = nil

    if careerItem then
        incidentNote = self:_findIncitingIncidentMatch(careerItem, career:IncitingIncident())
        if incidentNote then
            writeLog(string.format("Adding Inciting Incident [%s]", incidentNote.text:sub(1, 24)), STATUS.IMPL)
            local notes = self.codexToon:get_or_add("notes", {})
            notes[#notes + 1] = incidentNote
        end
    else
        writeLog(string.format("!!! Career [%s] not found in table.", careerGuid), STATUS.ERROR)
    end

    writeLog("Inciting Incident complete.", STATUS.INFO, -1)
end

--- Searches through background characteristics to find a matching inciting incident.
--- Iterates through all characteristics in the background item, filtering for BackgroundCharacteristic types
--- and searching their associated table rows for matches.
--- @private
--- @param careerItem table The background item from the game's Background table
--- @param incidentData CTIELookupTableDTO|CTIEBaseDTO The inciting incident data from the exported character
--- @return table|nil note The created note object if a match is found, nil otherwise
function CTIECareerImporter:_findIncitingIncidentMatch(careerItem, incidentData)
    for _, characteristic in pairs(careerItem.characteristics) do
        if self:_isBackgroundCharacteristic(characteristic) then
            local match = self:_searchCharacteristicRows(characteristic, incidentData)
            if match then
                return match
            end
        end
    end
    return nil
end

--- Determines if a characteristic is a BackgroundCharacteristic with a valid table ID.
--- Used to filter characteristics when searching for inciting incident matches.
--- @private
--- @param characteristic table The characteristic object to evaluate
--- @return boolean isBackgroundCharacteristic True if the characteristic is a BackgroundCharacteristic with a table ID
function CTIECareerImporter:_isBackgroundCharacteristic(characteristic)
    return characteristic.typeName == "BackgroundCharacteristic" and characteristic.tableid ~= nil
end

--- Searches through characteristic table rows to find an inciting incident match.
--- Retrieves the characteristic table and iterates through its rows, comparing against the incident data
--- using both direct ID matching and fuzzy name matching.
--- @private
--- @param characteristic table The background characteristic containing the table ID
--- @param incidentData CTIELookupTableDTO|CTIEBaseDTO The inciting incident data to match against
--- @return table|nil note The created note object if a match is found, nil otherwise
function CTIECareerImporter:_searchCharacteristicRows(characteristic, incidentData)
    writeDebug(string.format("INCITINGINCIDENT:: CHARACTERISTIC type [%s] table [%s]",
        characteristic.typeName, characteristic.tableid))

    local ct = dmhub.GetTable(BackgroundCharacteristic.characteristicsTable)
    local table = ct[characteristic.tableid]

    if table and table.rows then
        for _, row in pairs(table.rows) do
            writeDebug(string.format("INCITINGINCIDENT:: row[%s]", row.value.items[1].value:sub(1, 24)))

            if self:_incidentMatches(row, incidentData) then
                return self:_createIncitingIncidentNote(row, characteristic.tableid)
            end
        end
    end

    return nil
end

--- Determines if a table row matches the given inciting incident data.
--- Checks for matches using both direct row ID comparison and fuzzy name matching via _incidentNamesMatch.
--- @private
--- @param row table The table row to evaluate
--- @param incidentData CTIELookupTableDTO|CTIEBaseDTO The inciting incident data containing rowid and text
--- @return boolean matches True if the row matches the incident data
function CTIECareerImporter:_incidentMatches(row, incidentData)
    return row.id == incidentData:GetID() or
        self:_incidentNamesMatch(incidentData:GetName() or "", row.value.items[1].value)
end

--- Compares inciting incident names using fuzzy matching logic.
--- Extracts text content from between asterisk markers and uses sanitized string matching
--- to handle formatting differences between exported and game data.
--- @private
--- @param needle string The incident text from the exported data
--- @param haystack string The incident text from the game table row
--- @return boolean matches True if the extracted text content matches after sanitization
function CTIECareerImporter:_incidentNamesMatch(needle, haystack)
    writeDebug("INCITINGINCIDENT:: [%s] ?= [%s]", needle:sub(1, 40), haystack:sub(1, 40))
    local n1 = needle:match("^%*%*:?(.-):?%*%*")
    local h1 = haystack:match("^%*%*:?(.-):?%*%*")
    return CTIEUtils.SanitizedStringsMatch(n1, h1)
end

--- Creates a formatted note object for an inciting incident.
--- Constructs a character note with the appropriate title, text content, and metadata
--- for storage in the destination character's notes collection.
--- @private
--- @param row table The matching table row containing the incident text
--- @param tableid string The ID of the characteristic table containing the row
--- @return table note The formatted note object with text, title, rowid, and tableid
function CTIECareerImporter:_createIncitingIncidentNote(row, tableid)
    local item = row.value.items[1]
    return {
        text = item.value,
        title = "Inciting Incident",
        rowid = row.id,
        tableid = tableid
    }
end
