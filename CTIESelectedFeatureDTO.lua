local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for individual selected feature.
--- @class CTIESelectedFeatureDTO
CTIESelectedFeatureDTO = RegisterGameType("CTIESelectedFeatureDTO", "CTIEBaseDTO")
CTIESelectedFeatureDTO.__index = CTIESelectedFeatureDTO

--- Creates a new selected feature DTO instance.
--- @return CTIEBaseDTO|CTIESelectedFeatureDTO instance The new selected feature DTO instance
function CTIESelectedFeatureDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setData("selections", {})
    return instance
end

--- Sets the source for this selected feature.
--- @param source string The source description
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetSource(source)
    return self:_setData("source", source or "")
end

--- Gets the source for this selected feature.
--- @return string|nil source The source description
function CTIESelectedFeatureDTO:GetSource()
    return self:_getData("source")
end

--- Sets the choice type for this selected feature.
--- @param choiceType string The choice type (e.g., "CharacterFeatChoice")
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetChoiceType(choiceType)
    return self:_setData("choiceType", choiceType)
end

--- Gets the choice type for this selected feature.
--- @return string|nil choiceType The choice type
function CTIESelectedFeatureDTO:GetChoiceType()
    return self:_getData("choiceType")
end

--- Sets the categories for this selected feature.
--- @param categories table The categories table
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetCategories(categories)
    return self:_setData("categories", categories)
end

--- Gets the categories for this selected feature.
--- @return table|nil categories The categories table
function CTIESelectedFeatureDTO:GetCategories()
    return self:_getData("categories")
end

--- Adds a selection to this feature's selections array.
--- @param lookupTableDTO CTIELookupTableDTO The lookup table DTO to add
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:AddSelection(lookupTableDTO)
    local selections = self:_getData("selections") or {}
    table.insert(selections, lookupTableDTO)
    return self:_setData("selections", selections)
end

--- Gets all selections for this feature.
--- @return table selections Array of selection DTOs
function CTIESelectedFeatureDTO:GetSelections()
    return self:_getData("selections") or {}
end