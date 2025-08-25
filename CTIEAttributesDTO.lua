local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character attribute values.
--- Stores the actual attribute scores and modifiers for a character.
--- @class CTIEAttributesDTO
CTIEAttributesDTO = RegisterGameType("CTIEAttributesDTO", "CTIEBaseDTO")
CTIEAttributesDTO.__index = CTIEAttributesDTO

--- Creates a new attributes DTO instance.
--- @return CTIEBaseDTO|CTIEAttributesDTO instance The new attributes DTO instance
function CTIEAttributesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end