local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character cultural background.
--- Contains cultural traits, languages, and cultural bonuses.
--- @class CTIECultureDTO
CTIECultureDTO = RegisterGameType("CTIECultureDTO", "CTIEBaseDTO")
CTIECultureDTO.__index = CTIECultureDTO

--- Creates a new culture DTO instance.
--- @return CTIEBaseDTO|CTIECultureDTO instance The new culture DTO instance
function CTIECultureDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
