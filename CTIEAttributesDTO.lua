local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character attribute values.
--- Stores attribute base values as a simple key-value collection.
--- @class CTIEAttributesDTO
CTIEAttributesDTO = RegisterGameType("CTIEAttributesDTO", "CTIEBaseDTO")
CTIEAttributesDTO.__index = CTIEAttributesDTO

--- Creates a new attributes DTO instance.
--- @return CTIEBaseDTO|CTIEAttributesDTO instance The new attributes DTO instance
function CTIEAttributesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

--- Sets an attribute value with key validation.
--- Only accepts attribute keys defined in CTIEConfig.attributes.
--- @param attributeKey string The attribute key (must be in CTIEConfig.attributes)
--- @param baseValue number The base value for the attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetAttribute(attributeKey, baseValue)
    -- Validate attribute key
    local validKey = false
    for _, validAttr in ipairs(CTIEConfig.attributes) do
        if validAttr == attributeKey then
            validKey = true
            break
        end
    end

    if not validKey then
        writeLog(string.format("Invalid attribute key '%s'. Must be one of: %s", attributeKey, table.concat(CTIEConfig.attributes, ", ")), STATUS.ERROR)
        return self
    end

    self:_setProp(attributeKey, baseValue)
    return self
end

--- Gets an attribute value.
--- @param attributeKey string The attribute key to retrieve
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetAttribute(attributeKey)
    return self:_getProp(attributeKey)
end
