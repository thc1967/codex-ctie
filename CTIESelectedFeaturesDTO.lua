local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Container DTO for managing multiple selected features.
--- @class CTIESelectedFeaturesDTO
CTIESelectedFeaturesDTO = RegisterGameType("CTIESelectedFeaturesDTO", "CTIEBaseDTO")
CTIESelectedFeaturesDTO.__index = CTIESelectedFeaturesDTO

--- Creates a new selected features container DTO instance.
--- @return CTIEBaseDTO|CTIESelectedFeaturesDTO instance The new selected features container DTO instance
function CTIESelectedFeaturesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

--- Adds a selected feature to the container.
--- @param guid string The GUID key for the feature
--- @param selectedFeatureDTO CTIESelectedFeatureDTO The selected feature DTO to add
--- @return CTIESelectedFeaturesDTO self Returns self for method chaining
function CTIESelectedFeaturesDTO:AddFeature(guid, selectedFeatureDTO)
    return self:_setData(guid, selectedFeatureDTO)
end

--- Retrieves a selected feature by GUID.
--- @param guid string The GUID key for the feature
--- @return CTIESelectedFeatureDTO|nil feature The selected feature DTO or nil if not found
function CTIESelectedFeaturesDTO:GetFeature(guid)
    return self:_getData(guid)
end

--- Retrieves all selected features.
--- @return table features Table of all selected features with GUID keys
function CTIESelectedFeaturesDTO:GetAllFeatures()
    local features = {}
    for k, v in pairs(self) do
        if self:_isCTIEDTO(v) and v.typeName == "CTIESelectedFeatureDTO" then
            features[k] = v
        end
    end
    return features
end