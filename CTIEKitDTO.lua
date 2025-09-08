--- Data Transfer Object for character kit identifiers.
--- Stores equipment packages and starting gear selections.
--- @class CTIEKitDTO
--- @field kit1 CTIEBaseDTO|CTIELookupTableDTO Lookup Key for the first kit
--- @field kit2 CTIEBaseDTO|CTIELookupTableDTO Lookup Key for the second kit
CTIEKitDTO = RegisterGameType("CTIEKitDTO", "CTIEBaseDTO")
CTIEKitDTO.__index = CTIEKitDTO

--- Creates a new kit DTO instance.
--- @return CTIEBaseDTO|CTIEKitDTO instance The new kit DTO instance
function CTIEKitDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("kit1", CTIELookupTableDTO:new())
    instance:_setProp("kit2", CTIELookupTableDTO:new())
    return instance
end

--- Gets the first kit lookup data.
--- @return CTIELookupTableDTO kit1 The first kit lookup DTO
function CTIEKitDTO:Kit1()
    return self:_getProp("kit1")
end

--- Gets the second kit lookup data.
--- @return CTIELookupTableDTO kit2 The second kit lookup DTO
function CTIEKitDTO:Kit2()
    return self:_getProp("kit2")
end
