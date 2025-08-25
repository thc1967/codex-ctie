local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character ancestry information.
--- Handles ancestry-related character data and features.
--- @class CTIEAncestryDTO
CTIEAncestryDTO = RegisterGameType("CTIEAncestryDTO", "CTIEBaseDTO")
CTIEAncestryDTO.__index = CTIEAncestryDTO

--- Creates a new ancestry DTO instance.
--- @return CTIEBaseDTO|CTIEAncestryDTO instance The new ancestry DTO instance
function CTIEAncestryDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end