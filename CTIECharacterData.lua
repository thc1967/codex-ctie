--- CTIECharacterData serves as a Data Transfer Object (DTO) for character import and export operations.
--- This class maintains a hierarchical token/character structure that mirrors the Codex game system's
--- data organization, providing JSON serialization capabilities and character name extraction utilities.
--- @class CTIECharacterData
CTIECharacterData = RegisterGameType("CTIECharacterData")
CTIECharacterData.__index = CTIECharacterData

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog

--- Creates a new CTIECharacterData instance with an initialized token/character structure.
--- Establishes the nested hierarchy where token contains character data, matching the Codex object model.
--- @return CTIECharacterData instance The new character data instance with empty token and character objects
function CTIECharacterData:new()
    local instance = setmetatable({}, self)

    instance.token = {
        character = {},
    }

    return instance
end

--- Retrieves the character's display name from the token data.
--- Returns a default name if the token name is missing or empty, ensuring consistent naming behavior
--- for UI display and file operations.
--- @return string name The character's name, or "Unnamed" if no valid name is present
function CTIECharacterData:GetCharacterName()
    if self.token.name and #self.token.name > 0 then
        return self.token.name
    else
        return "Unnamed"
    end
end

--- Converts the character data to JSON format for export operations.
--- Serializes the internal token structure containing all character data into a JSON string
--- suitable for file storage or network transmission.
--- @return string json The JSON representation of the character's token data
function CTIECharacterData:ToJSON()
    return json(self.token)
end

--- Populates the character data from a JSON string during import operations.
--- Parses the provided JSON text and validates the structure before updating the internal token data.
--- Handles parsing errors gracefully with appropriate logging and returns nil on failure.
--- @param jsonText string The JSON string containing character data to import
--- @return table|nil token The parsed token data if successful, nil if parsing failed or input was invalid
function CTIECharacterData:FromJSON(jsonText)
    writeDebug("CTIECharacterData.FromJSON():: %d\n%s", jsonText and #jsonText or 0, jsonText)
    if not jsonText then
        writeLog("!!!! Empty import file.", CTIEUtils.STATUS.WARN)
        return nil
    end

    local parsedData = dmhub.FromJson(jsonText).result
    if not parsedData then
        writeLog("!!!! Invalid JSON file format.", CTIEUtils.STATUS.WARN)
        return nil
    end

    self.token = parsedData
    writeDebug("CTIECharacterData.FromJSON()::TOKEN::\n%s", json(self.token))

    return self.token
end