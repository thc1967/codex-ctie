--- Data Transfer Object for character attribute values.
--- Stores attribute base values as a simple key-value collection.
--- @class CTIEAttributesDTO
--- @field mgt number Might attribute base value
--- @field agl number Agility attribute base value
--- @field rea number Reason attribute base value
--- @field inu number Intuition attribute base value
--- @field prs number Presence attribute base value
CTIEAttributesDTO = RegisterGameType("CTIEAttributesDTO", "CTIEBaseDTO")
CTIEAttributesDTO.__index = CTIEAttributesDTO

--- Creates a new attributes DTO instance.
--- @return CTIEBaseDTO|CTIEAttributesDTO instance The new attributes DTO instance
function CTIEAttributesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("mgt", 0)
    instance:_setProp("agl", 0)
    instance:_setProp("rea", 0)
    instance:_setProp("inu", 0)
    instance:_setProp("prs", 0)
    return instance
end

--- Sets the Might attribute value.
--- @param baseValue number The base value for the Might attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetMgt(baseValue)
    return self:_setProp("mgt", baseValue)
end

--- Gets the Might attribute value.
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetMgt()
    return self:_getProp("mgt")
end

--- Sets the Agility attribute value.
--- @param baseValue number The base value for the Agility attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetAgl(baseValue)
    return self:_setProp("agl", baseValue)
end

--- Gets the Agility attribute value.
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetAgl()
    return self:_getProp("agl")
end

--- Sets the Reason attribute value.
--- @param baseValue number The base value for the Reason attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetRea(baseValue)
    return self:_setProp("rea", baseValue)
end

--- Gets the Reason attribute value.
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetRea()
    return self:_getProp("rea")
end

--- Sets the Intuition attribute value.
--- @param baseValue number The base value for the Intuition attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetInu(baseValue)
    return self:_setProp("inu", baseValue)
end

--- Gets the Intuition attribute value.
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetInu()
    return self:_getProp("inu")
end

--- Sets the Presence attribute value.
--- @param baseValue number The base value for the Presence attribute
--- @return CTIEAttributesDTO self Returns self for method chaining
function CTIEAttributesDTO:SetPrs(baseValue)
    return self:_setProp("prs", baseValue)
end

--- Gets the Presence attribute value.
--- @return number|nil baseValue The base value, or nil if not set
function CTIEAttributesDTO:GetPrs()
    return self:_getProp("prs")
end
