--- Current CTIE file format version for metadata and compatibility checking.
--- Increment this when making breaking changes to the data structure or format.
local CTIE_VERSION = 1

--- CTIECharacterData serves as a Data Transfer Object (DTO) for character import and export operations.
--- This class maintains a hierarchical token/character structure that mirrors the Codex game system's
--- data organization, providing JSON serialization capabilities, character name extraction utilities,
--- and versioned metadata support for backward compatibility during format transitions.
--- @class CTIECharacterData
CTIECharacterData = RegisterGameType("CTIECharacterData")
CTIECharacterData.__index = CTIECharacterData

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog

--- Creates a new CTIECharacterData instance with versioned metadata and token/character structure.
--- Establishes the nested hierarchy with metadata for version tracking and export information,
--- plus the token structure containing character data, matching the Codex object model.
--- @return CTIECharacterData instance The new character data instance with metadata and empty token/character objects
function CTIECharacterData:new()
    local instance = setmetatable({}, self)
    instance.data = {
        metadata = {
            version = CTIE_VERSION,
            exportTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), -- ISO 8601 UTC format
            exportSource = "Codex CTIE",
            characterName = "Unnamed"
        },
        token = {
            character = {},
        }
    }
    return instance
end

--- Internal helper to retrieve the token structure.
--- Always returns the token reference from the internal data structure.
--- @private
--- @return table token The token structure containing character data
function CTIECharacterData:_getToken()
    return self.data.token
end

--- Internal helper to retrieve the character structure.
--- Always returns the character reference from the internal data structure.
--- @private
--- @return table character The character structure containing character data
function CTIECharacterData:_getCharacter()
    return self:_getToken().character
end

--- Internal helper to retrieve the metadata structure.
--- Always returns the metadata reference from the internal data structure.
--- @private
--- @return table metadata The metadata structure with version and export information
function CTIECharacterData:_getMetadata()
    return self.data.metadata
end

--- Retrieves the character's display name from the token data.
--- Returns a default name if the token name is missing or empty, ensuring consistent naming behavior
--- for UI display and file operations.
--- @return string name The character's name, or "Unnamed" if no valid name is present
function CTIECharacterData:GetCharacterName()
    local t = self:_getToken()
    if t.name and #t.name > 0 then
        return t.name
    else
        return "Unnamed"
    end
end

--- Sets the character's display name with optional chaining support.
--- Updates both the token name and metadata character name for consistency.
--- @param name string The name to assign to the character (nil or empty string will result in "Unnamed")
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCharacterName(name)
    local finalName
    if name and #name > 0 then
        finalName = name
    else
        finalName = "Unnamed"
    end

    self:_getToken().name = finalName

    -- Update metadata if available
    if self:_getMetadata() then
        self:_getMetadata().characterName = finalName
    end

    return self
end

--- Sets the portrait offset coordinates with optional chaining support.
--- Stores the offset as a table with x and y coordinates for later conversion to Vector2.
--- @param x number The horizontal offset coordinate (defaults to 0 if nil)
--- @param y number The vertical offset coordinate (defaults to 0 if nil)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetPortraitOffset(x, y)
    self:_getToken().portraitOffset = {x = x or 0, y = y or 0}
    return self
end

--- Retrieves the portrait offset coordinates as a table.
--- Returns the raw coordinate table suitable for Vector2 conversion or nil if not set.
--- @return table|nil offset The offset table with x and y fields, or nil if no offset is set
function CTIECharacterData:GetPortraitOffset()
    return self:_getToken().portraitOffset
end

--- Checks if portrait offset has been configured.
--- @return boolean hasOffset True if portrait offset coordinates are set, false otherwise
function CTIECharacterData:HasPortraitOffset()
    return self:_getToken().portraitOffset ~= nil
end

--- Sets a lookup record for the specified character property.
--- Stores the lookup record containing table name, GUID, and display name for later resolution.
--- @param propertyName string The character property name (e.g., "chartypeid", "complicationid", "kitid")
--- @param lookupRecord table The lookup record with tableName, guid, and name fields
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetLookupRecord(propertyName, lookupRecord)
    self:_getCharacter()[propertyName] = lookupRecord
    return self
end

--- Retrieves a lookup record for the specified character property.
--- @param propertyName string The character property name to retrieve
--- @return table|nil lookupRecord The lookup record with tableName, guid, and name, or nil if not set
function CTIECharacterData:GetLookupRecord(propertyName)
    return self:_getCharacter()[propertyName]
end

--- Checks if a lookup record has been set for the specified character property.
--- @param propertyName string The character property name to check
--- @return boolean hasRecord True if the property has a lookup record, false otherwise
function CTIECharacterData:HasLookupRecord(propertyName)
    return self:_getCharacter()[propertyName] ~= nil
end

--- Sets a token property with automatic deep copying for table values.
--- Handles both primitive values and tables, applying deep copy for tables to prevent reference sharing.
--- @param propertyName string The token property name (e.g., "portrait", "popoutScale", "saddles")
--- @param value any The value to set (tables will be deep copied, primitives stored directly)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetTokenProperty(propertyName, value)
    if type(value) == "table" then
        self:_getToken()[propertyName] = DeepCopy(value)
    else
        self:_getToken()[propertyName] = value
    end
    return self
end

--- Retrieves a token property value.
--- @param propertyName string The token property name to retrieve
--- @return any value The token property value, or nil if not set
function CTIECharacterData:GetTokenProperty(propertyName)
    return self:_getToken()[propertyName]
end

--- Checks if a token property has been set.
--- @param propertyName string The token property name to check
--- @return boolean hasProperty True if the property exists, false otherwise
function CTIECharacterData:HasTokenProperty(propertyName)
    return self:_getToken()[propertyName] ~= nil
end

--- Sets a character property with automatic deep copying for table values.
--- Handles both primitive values and tables, applying deep copy for tables to prevent reference sharing.
--- @param propertyName string The character property name (e.g., "attributeBuild")
--- @param value any The value to set (tables will be deep copied, primitives stored directly)
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCharacterProperty(propertyName, value)
    if type(value) == "table" then
        self:_getCharacter()[propertyName] = DeepCopy(value)
    else
        self:_getCharacter()[propertyName] = value
    end
    return self
end

--- Retrieves a character property value.
--- @param propertyName string The character property name to retrieve
--- @return any value The character property value, or nil if not set
function CTIECharacterData:GetCharacterProperty(propertyName)
    return self:_getCharacter()[propertyName]
end

--- Checks if a character property has been set.
--- @param propertyName string The character property name to check
--- @return boolean hasProperty True if the property exists, false otherwise
function CTIECharacterData:HasCharacterProperty(propertyName)
    return self:_getCharacter()[propertyName] ~= nil
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
    self:_getCharacter().attributes = attributes
    return self
end

--- Retrieves the character attributes data.
--- @return table attributes The attributes table with baseValue and id for each attribute
function CTIECharacterData:GetAttributes()
    return self:_getCharacter().attributes or {}
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
    self:_getToken().ownerId = ownerId
    return self
end

--- Gets the token owner ID.
--- @return string|nil ownerId The owner ID, or nil if not set
function CTIECharacterData:GetOwnerId()
    return self:_getToken().ownerId
end

--- Sets the token party ID.
--- @param partyId string|nil The party GUID
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetPartyId(partyId)
    self:_getToken().partyId = partyId
    return self
end

--- Gets the token party ID.
--- @return string|nil partyId The party GUID, or nil if not set
function CTIECharacterData:GetPartyId()
    return self:_getToken().partyId
end

--- Sets the character ancestry data including race and features.
--- @param ancestry table The ancestry data with raceid and features
--- @return CTIECharacterData self Returns this instance to support method chaining  
function CTIECharacterData:SetAncestry(ancestry)
    self:_getCharacter().ancestry = ancestry
    return self
end

--- Gets the character ancestry data.
--- @return table|nil ancestry The ancestry data, or nil if not set
function CTIECharacterData:GetAncestry()
    return self:_getCharacter().ancestry
end

--- Sets the character career data including background and features.
--- @param career table The career data with backgroundid, incitingIncident, and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCareer(career)
    self:_getCharacter().career = career
    return self
end

--- Gets the character career data.
--- @return table|nil career The career data, or nil if not set
function CTIECharacterData:GetCareer()
    return self:_getCharacter().career
end

--- Sets the character features data including background and features.
--- @param features table The features data
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCharacterFeatures(features)
    self:_getCharacter().characterFeatures = features
    return self
end

--- Gets the character features data.
--- @return table|nil features The features data, or nil if not set
function CTIECharacterData:GetCharacterFeatures()
    return self:_getCharacter().characterFeatures
end

--- Sets the character culture data including aspects and features.
--- @param culture table The culture data with aspects and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetCulture(culture)
    self:_getCharacter().culture = culture
    return self
end

--- Gets the character culture data.
--- @return table|nil culture The culture data, or nil if not set
function CTIECharacterData:GetCulture()
    return self:_getCharacter().culture
end

--- Sets the character classes data including levels and features.
--- @param classes table The classes array with class information and features
--- @return CTIECharacterData self Returns this instance to support method chaining
function CTIECharacterData:SetClasses(classes)
    self:_getCharacter().classes = classes
    return self
end

--- Gets the character classes data.
--- @return table|nil classes The classes array, or nil if not set
function CTIECharacterData:GetClasses()
    return self:_getCharacter().classes
end

--- Converts the character data to JSON format for export operations.
--- Serializes the internal data structure (including metadata) into a JSON string
--- suitable for file storage or network transmission. Always uses versioned format.
--- @return string json The JSON representation of the complete character data including metadata
function CTIECharacterData:ToJSON()
    return json(self.data)
end

--- Populates the character data from a JSON string during import operations with legacy conversion.
--- Parses the provided JSON text, detects format version through metadata presence, and converts
--- legacy format to current internal structure. Always maintains internal data structure regardless
--- of input format. Handles parsing errors gracefully and returns nil on failure.
--- @param jsonText string The JSON string containing character data to import
--- @return table|nil data The parsed data structure if successful, nil if parsing failed or input was invalid
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

    -- Detect format version through metadata presence
    if parsedData.metadata and parsedData.metadata.version >= 1 then
        -- New versioned format - use directly
        writeDebug("CTIECharacterData.FromJSON():: Using versioned format v%d", parsedData.metadata.version)
        self.data = parsedData
    else
        -- Convert legacy token structure to new data structure
        self.data = {
            metadata = {
                version = CTIE_VERSION,
                exportTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                exportSource = "Codex CTIE (Legacy Import)",
                characterName = (parsedData.name and #parsedData.name > 0) and parsedData.name or "Unnamed"
            },
            token = parsedData
        }
    end

    writeDebug("CTIECharacterData.FromJSON():: FINAL DATA::\n%s", json(self.data))
    return self.data
end
