--- Data Transfer Object for individual culture aspect information.
--- Handles aspect-related character data and features.
--- @class CTIECultureAspectDTO
--- @field aspectid CTIEBaseDTO|CTIELookupTableDTO Lookup Key for the culture aspect
--- @field selectedFeatures CTIEBaseDTO|CTIESelectedFeaturesDTO Selected features for the aspect
CTIECultureAspectDTO = RegisterGameType("CTIECultureAspectDTO", "CTIEBaseDTO")
CTIECultureAspectDTO.__index = CTIECultureAspectDTO

--- Creates a new culture aspect DTO instance.
--- @return CTIEBaseDTO|CTIECultureAspectDTO instance The new culture aspect DTO instance
function CTIECultureAspectDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("aspectid", CTIELookupTableDTO:new())
    instance:_setProp("selectedFeatures", CTIESelectedFeaturesDTO:new())
    return instance
end

--- Gets the aspect ID lookup data.
--- @return CTIELookupTableDTO aspectid The aspect ID lookup DTO
function CTIECultureAspectDTO:GuidLookup()
    return self:_getProp("aspectid")
end

--- Gets the selected features data.
--- @return CTIESelectedFeaturesDTO selectedFeatures The selected features DTO
function CTIECultureAspectDTO:SelectedFeatures()
    return self:_getProp("selectedFeatures")
end