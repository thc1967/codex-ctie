local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character career information.
--- Contains profession, background, and career-specific data.
--- @class CTIECareerDTO
CTIECareerDTO = RegisterGameType("CTIECareerDTO", "CTIEBaseDTO")
CTIECareerDTO.__index = CTIECareerDTO

--- Creates a new career DTO instance.
--- @return CTIEBaseDTO|CTIECareerDTO instance The new career DTO instance
function CTIECareerDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
