--- Container DTO for managing multiple selected features as an array.
--- @class CTIESelectedFeaturesDTO
CTIESelectedFeaturesDTO = RegisterGameType("CTIESelectedFeaturesDTO", "CTIEBaseDTO")
CTIESelectedFeaturesDTO.__index = CTIESelectedFeaturesDTO

--- Creates a new selected features container DTO instance.
--- @return CTIEBaseDTO|CTIESelectedFeaturesDTO instance The new selected features container DTO instance
function CTIESelectedFeaturesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("features", {})
    return instance
end

--- Adds a selected feature to the container array.
--- @param selectedFeatureDTO CTIESelectedFeatureDTO The selected feature DTO to add
--- @return CTIESelectedFeaturesDTO self Returns self for method chaining
function CTIESelectedFeaturesDTO:AddFeature(selectedFeatureDTO)
    local features = self:_getProp("features") or {}
    table.insert(features, selectedFeatureDTO)
    return self:_setProp("features", features)
end

--- Retrieves a selected feature by choice ID.
--- @param choiceId string The choice ID to search for
--- @return CTIESelectedFeatureDTO|nil feature The selected feature DTO or nil if not found
function CTIESelectedFeaturesDTO:GetFeature(choiceId)
    local features = self:_getProp("features") or {}
    for _, feature in pairs(features) do
        if feature:GetChoiceId() == choiceId then
            return feature
        end
    end
    return nil
end

--- Retrieves all selected features as an array.
--- @return table features Array of all selected feature DTOs
function CTIESelectedFeaturesDTO:GetAllFeatures()
    return self:_getProp("features") or {}
end