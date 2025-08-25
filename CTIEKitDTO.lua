local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character kit identifier.
--- Stores equipment packages and starting gear selections.
--- @class CTIEKitDTO
CTIEKitDTO = RegisterGameType("CTIEKitDTO", "CTIEBaseDTO")
CTIEKitDTO.__index = CTIEKitDTO

--- Creates a new kit ID DTO instance.
--- @return CTIEBaseDTO|CTIEKitDTO instance The new kit ID DTO instance
function CTIEKitDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
