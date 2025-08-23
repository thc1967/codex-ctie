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

--- Sets the character's display name with optional chaining support.
--- @param name string The name to assign to the character (nil or empty string will result in "Unnamed")
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCharacterName(name)
    if name and #name > 0 then
        self.token.name = name
    else
        self.token.name = "Unnamed"
    end
    return self
end

--- Sets the portrait offset coordinates with optional chaining support.
--- Stores the offset as a table with x and y coordinates for later conversion to Vector2.
--- @param x number The horizontal offset coordinate (defaults to 0 if nil)
--- @param y number The vertical offset coordinate (defaults to 0 if nil)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetPortraitOffset(x, y)
    self.token.portraitOffset = {x = x or 0, y = y or 0}
    return self
end

--- Retrieves the portrait offset coordinates as a table.
--- Returns the raw coordinate table suitable for Vector2 conversion or nil if not set.
--- @return table|nil offset The offset table with x and y fields, or nil if no offset is set
function CTIECharacterData:GetPortraitOffset()
    return self.token.portraitOffset
end

--- Checks if portrait offset has been configured.
--- @return boolean hasOffset True if portrait offset coordinates are set, false otherwise
function CTIECharacterData:HasPortraitOffset()
    return self.token.portraitOffset ~= nil
end

--- Sets a lookup record for the specified character property.
--- Stores the lookup record containing table name, GUID, and display name for later resolution.
--- @param propertyName string The character property name (e.g., "chartypeid", "complicationid", "kitid")
--- @param lookupRecord table The lookup record with tableName, guid, and name fields
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetLookupRecord(propertyName, lookupRecord)
    self.token.character[propertyName] = lookupRecord
    return self
end

--- Retrieves a lookup record for the specified character property.
--- @param propertyName string The character property name to retrieve
--- @return table|nil lookupRecord The lookup record with tableName, guid, and name, or nil if not set
function CTIECharacterData:GetLookupRecord(propertyName)
    return self.token.character[propertyName]
end

--- Checks if a lookup record has been set for the specified character property.
--- @param propertyName string The character property name to check
--- @return boolean hasRecord True if the property has a lookup record, false otherwise
function CTIECharacterData:HasLookupRecord(propertyName)
    return self.token.character[propertyName] ~= nil
end

--- Sets a token property with automatic deep copying for table values.
--- Handles both primitive values and tables, applying deep copy for tables to prevent reference sharing.
--- @param propertyName string The token property name (e.g., "portrait", "popoutScale", "saddles")
--- @param value any The value to set (tables will be deep copied, primitives stored directly)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetTokenProperty(propertyName, value)
    if type(value) == "table" then
        self.token[propertyName] = DeepCopy(value)
    else
        self.token[propertyName] = value
    end
    return self
end

--- Retrieves a token property value.
--- @param propertyName string The token property name to retrieve
--- @return any value The token property value, or nil if not set
function CTIECharacterData:GetTokenProperty(propertyName)
    return self.token[propertyName]
end

--- Checks if a token property has been set.
--- @param propertyName string The token property name to check
--- @return boolean hasProperty True if the property exists, false otherwise
function CTIECharacterData:HasTokenProperty(propertyName)
    return self.token[propertyName] ~= nil
end

--- Sets a character property with automatic deep copying for table values.
--- Handles both primitive values and tables, applying deep copy for tables to prevent reference sharing.
--- @param propertyName string The character property name (e.g., "attributeBuild")
--- @param value any The value to set (tables will be deep copied, primitives stored directly)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCharacterProperty(propertyName, value)
    if type(value) == "table" then
        self.token.character[propertyName] = DeepCopy(value)
    else
        self.token.character[propertyName] = value
    end
    return self
end

--- Retrieves a character property value.
--- @param propertyName string The character property name to retrieve
--- @return any value The character property value, or nil if not set
function CTIECharacterData:GetCharacterProperty(propertyName)
    return self.token.character[propertyName]
end

--- Checks if a character property has been set.
--- @param propertyName string The character property name to check
--- @return boolean hasProperty True if the property exists, false otherwise
function CTIECharacterData:HasCharacterProperty(propertyName)
    return self.token.character[propertyName] ~= nil
end

--- Sets the character attributes from source attribute data.
--- Extracts baseValue and id for each configured attribute and stores in the DTO format.
--- @param sourceAttributes table The source attributes object containing full attribute data
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetAttributes(sourceAttributes)
    local attributes = {}
    for _, attr in ipairs(CTIEConfig.attributes) do
        if sourceAttributes[attr] then
            attributes[attr] = {
                baseValue = sourceAttributes[attr].baseValue,
                id = sourceAttributes[attr].id
            }
        end
    end
    self.token.character.attributes = attributes
    return self
end

--- Retrieves the character attributes data.
--- @return table attributes The attributes table with baseValue and id for each attribute
function CTIECharacterData:GetAttributes()
    return self.token.character.attributes or {}
end

--- Generates a formatted summary string of attribute values for logging.
--- Creates a space-separated list of attribute abbreviations with their base values.
--- @return string summary The formatted attribute summary (e.g., "M +2 A +1 I +3 P +0 R +1")
function CTIECharacterData:GetAttributesSummary()
    local attributes = self:GetAttributes()
    local summary = ""
    for _, attr in ipairs(CTIEConfig.attributes) do
        if attributes[attr] and attributes[attr].baseValue then
            summary = string.format("%s %s %+d ", summary, attr:sub(1,1):upper(), attributes[attr].baseValue)
        end
    end
    return summary:trim()
end

--- Sets the token owner ID.
--- @param ownerId string|nil The owner ID (user ID or "PARTY")
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetOwnerId(ownerId)
    self.token.ownerId = ownerId
    return self
end

--- Gets the token owner ID.
--- @return string|nil ownerId The owner ID, or nil if not set
function CTIECharacterData:GetOwnerId()
    return self.token.ownerId
end

--- Sets the token party ID.
--- @param partyId string|nil The party GUID
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetPartyId(partyId)
    self.token.partyId = partyId
    return self
end

--- Gets the token party ID.
--- @return string|nil partyId The party GUID, or nil if not set
function CTIECharacterData:GetPartyId()
    return self.token.partyId
end

--- Sets the character ancestry data including race and features.
--- @param ancestry table The ancestry data with raceid and features
--- @return CTIECharacterData self Returns this instance to support method chaining  
function CTIECharacterData:SetAncestry(ancestry)
    self.token.character.ancestry = ancestry
    return self
end

--- Gets the character ancestry data.
--- @return table|nil ancestry The ancestry data, or nil if not set
function CTIECharacterData:GetAncestry()
    return self.token.character.ancestry
end

--- Sets the character career data including background and features.
--- @param career table The career data with backgroundid, incitingIncident, and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCareer(career)
    self.token.character.career = career
    return self
end

--- Gets the character career data.
--- @return table|nil career The career data, or nil if not set
function CTIECharacterData:GetCareer()
    return self.token.character.career
end

--- Sets the character culture data including aspects and features.
--- @param culture table The culture data with aspects and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCulture(culture)
    self.token.character.culture = culture
    return self
end

--- Gets the character culture data.
--- @return table|nil culture The culture data, or nil if not set
function CTIECharacterData:GetCulture()
    return self.token.character.culture
end

--- Sets the character classes data including levels and features.
--- @param classes table The classes array with class information and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetClasses(classes)
    self.token.character.classes = classes
    return self
end

--- Gets the character classes data.
--- @return table|nil classes The classes array, or nil if not set
function CTIECharacterData:GetClasses()
    return self.token.character.classes
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

    return self
end
