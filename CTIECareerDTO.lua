local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character career information.
--- Contains profession, background, and career-specific data.
--- @class CTIECareerDTO
--- @field backgroundid CTIEBaseDTO|CTIELookupTableDTO Lookup Key
--- @field incitingIncident CTIEBaseDTO|CTIELookupTableDTO Lookup Key
--- @field selectedFeatures CTIEBaseDTO|CTIESelectedFeaturesDTO Selected features for the career
CTIECareerDTO = RegisterGameType("CTIECareerDTO", "CTIEBaseDTO")
CTIECareerDTO.__index = CTIECareerDTO

--- Creates a new career DTO instance.
--- @return CTIEBaseDTO|CTIECareerDTO instance The new career DTO instance
function CTIECareerDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance.backgroundid = CTIELookupTableDTO:new()
    instance.incitingIncident = CTIELookupTableDTO:new()
    instance.selectedFeatures = CTIESelectedFeaturesDTO:new()
    return instance
end
