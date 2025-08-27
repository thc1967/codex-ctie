--- Data Transfer Object for individual selected feature.
--- @class CTIESelectedFeatureDTO
CTIESelectedFeatureDTO = RegisterGameType("CTIESelectedFeatureDTO", "CTIEBaseDTO")
CTIESelectedFeatureDTO.__index = CTIESelectedFeatureDTO

--- Creates a new selected feature DTO instance.
--- @return CTIEBaseDTO|CTIESelectedFeatureDTO instance The new selected feature DTO instance
function CTIESelectedFeatureDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("selections", {})
    return instance
end

--- Sets the choice ID for this selected feature.
--- @param choiceId string The choice ID (typically a GUID)
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetChoiceId(choiceId)
    return self:_setProp("choiceId", choiceId)
end

--- Gets the choice ID for this selected feature.
--- @return string|nil choiceId The choice ID
function CTIESelectedFeatureDTO:GetChoiceId()
    return self:_getProp("choiceId")
end

--- Sets the source for this selected feature.
--- @param source string The source description
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetSource(source)
    return self:_setProp("source", source or "")
end

--- Gets the source for this selected feature.
--- @return string|nil source The source description
function CTIESelectedFeatureDTO:GetSource()
    return self:_getProp("source")
end

--- Sets the choice type for this selected feature.
--- @param choiceType string The choice type (e.g., "CharacterFeatChoice")
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetChoiceType(choiceType)
    return self:_setProp("choiceType", choiceType)
end

--- Gets the choice type for this selected feature.
--- @return string|nil choiceType The choice type
function CTIESelectedFeatureDTO:GetChoiceType()
    return self:_getProp("choiceType")
end

--- Sets the categories for this selected feature.
--- @param categories table The categories table
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:SetCategories(categories)
    return self:_setProp("categories", categories)
end

--- Gets the categories for this selected feature.
--- @return table|nil categories The categories table
function CTIESelectedFeatureDTO:GetCategories()
    return self:_getProp("categories")
end

--- Adds a selection to this feature's selections array.
--- @param lookupTableDTO CTIELookupTableDTO The lookup table DTO to add
--- @return CTIESelectedFeatureDTO self Returns self for method chaining
function CTIESelectedFeatureDTO:AddSelection(lookupTableDTO)
    local selections = self:_getProp("selections") or {}
    table.insert(selections, lookupTableDTO)
    return self:_setProp("selections", selections)
end

--- Gets all selections for this feature.
--- @return table selections Array of selection DTOs
function CTIESelectedFeatureDTO:GetSelections()
    return self:_getProp("selections") or {}
end