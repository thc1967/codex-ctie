--- Data Transfer Object for character attribute build configuration.
--- Manages how character attributes are constructed and allocated.
--- @class CTIEAttributeBuildDTO
CTIEAttributeBuildDTO = RegisterGameType("CTIEAttributeBuildDTO", "CTIEBaseDTO")
CTIEAttributeBuildDTO.__index = CTIEAttributeBuildDTO

--- Creates a new attribute build DTO instance.
--- @return CTIEBaseDTO|CTIEAttributeBuildDTO instance The new attribute build DTO instance
function CTIEAttributeBuildDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end
