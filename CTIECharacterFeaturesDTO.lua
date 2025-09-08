--- Data Transfer Object for character features and abilities.
--- Manages special features, traits, and abilities granted to the character.
--- @class CTIECharacterFeaturesDTO
CTIECharacterFeaturesDTO = RegisterGameType("CTIECharacterFeaturesDTO", "CTIEBaseDTO")
CTIECharacterFeaturesDTO.__index = CTIECharacterFeaturesDTO

--- Creates a new character features DTO instance.
--- @return CTIEBaseDTO|CTIECharacterFeaturesDTO instance The new character features DTO instance
function CTIECharacterFeaturesDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

--- Converts character features DTO to table format for JSON serialization.
--- @return table characterFeatures The character features as a serializable table
function CTIECharacterFeaturesDTO:ToTable()
    return {}
end