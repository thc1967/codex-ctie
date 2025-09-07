local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character ancestry information.
--- Handles ancestry-related character data and features.
--- @class CTIEAncestryDTO
--- @field raceid CTIEBaseDTO|CTIELookupTableDTO Lookup Key for the character's race
--- @field selectedFeatures CTIEBaseDTO|CTIESelectedFeaturesDTO Selected features for the ancestry
CTIEAncestryDTO = RegisterGameType("CTIEAncestryDTO", "CTIEBaseDTO")
CTIEAncestryDTO.__index = CTIEAncestryDTO

--- Creates a new ancestry DTO instance.
--- @return CTIEBaseDTO|CTIEAncestryDTO instance The new ancestry DTO instance
function CTIEAncestryDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("raceid", CTIELookupTableDTO:new())
    instance:_setProp("selectedFeatures", CTIESelectedFeaturesDTO:new())
    return instance
end

--- Gets the race ID lookup data.
--- @return CTIELookupTableDTO raceid The race ID lookup DTO
function CTIEAncestryDTO:GuidLookup()
    return self:_getProp("raceid")
end

--- Gets the selected features data.
--- @return CTIESelectedFeaturesDTO selectedFeatures The selected features DTO
function CTIEAncestryDTO:SelectedFeatures()
    return self:_getProp("selectedFeatures")
end