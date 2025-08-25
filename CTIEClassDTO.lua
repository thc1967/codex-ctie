local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character class information.
--- Contains class levels, features, and class-specific progression data.
--- @class CTIEClassDTO
CTIEClassDTO = RegisterGameType("CTIEClassDTO", "CTIEBaseDTO")
CTIEClassDTO.__index = CTIEClassDTO

--- Creates a new classes DTO instance.
--- @return CTIEBaseDTO|CTIEClassDTO instance The new classes DTO instance
function CTIEClassDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

--- Converts classes DTO to table format for JSON serialization.
--- @return table classes The class data as a serializable table
function CTIEClassDTO:ToTable()
    return {}
end