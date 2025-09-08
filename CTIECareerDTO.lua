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
    instance:_setProp("backgroundid", CTIELookupTableDTO:new())
    instance:_setProp("incitingIncident", CTIELookupTableDTO:new())
    instance:_setProp("selectedFeatures", CTIESelectedFeaturesDTO:new())
    return instance
end

--- Gets the background ID lookup data.
--- @return CTIELookupTableDTO backgroundid The background ID lookup DTO
function CTIECareerDTO:GuidLookup()
    return self:_getProp("backgroundid")
end

--- Gets the inciting incident lookup data.
--- @return CTIELookupTableDTO incitingIncident The inciting incident lookup DTO
function CTIECareerDTO:IncitingIncident()
    return self:_getProp("incitingIncident")
end

--- Gets the selected features data.
--- @return CTIESelectedFeaturesDTO selectedFeatures The selected features DTO
function CTIECareerDTO:SelectedFeatures()
    return self:_getProp("selectedFeatures")
end
