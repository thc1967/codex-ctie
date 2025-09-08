--- Data Transfer Object for character innate activated abilities.
--- Manages supernatural or special abilities that can be actively triggered.
--- @class CTIEInnateActivatedAbilitiesDTO
CTIEInnateActivatedAbilitiesDTO = RegisterGameType("CTIEInnateActivatedAbilitiesDTO", "CTIEBaseDTO")
CTIEInnateActivatedAbilitiesDTO.__index = CTIEInnateActivatedAbilitiesDTO

--- Creates a new innate activated abilities DTO instance.
--- @return CTIEBaseDTO|CTIEInnateActivatedAbilitiesDTO instance The new innate activated abilities DTO instance
function CTIEInnateActivatedAbilitiesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
