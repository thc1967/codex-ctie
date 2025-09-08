--- Data Transfer Object for character damage resistances and immunities.
--- Manages resistance to various damage types and environmental effects.
--- @class CTIEResistancesDTO
CTIEResistancesDTO = RegisterGameType("CTIEResistancesDTO", "CTIEBaseDTO")
CTIEResistancesDTO.__index = CTIEResistancesDTO

--- Creates a new resistances DTO instance.
--- @return CTIEBaseDTO|CTIEResistancesDTO instance The new resistances DTO instance
function CTIEResistancesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
