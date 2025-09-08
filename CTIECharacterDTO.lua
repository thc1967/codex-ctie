--- Data Transfer Object for complete character mechanical data.
--- Aggregates all character systems including ancestry, classes, attributes, and features.
--- @class CTIECharacterDTO
--- @field ancestry CTIEBaseDTO|CTIEAncestryDTO Character ancestry data
--- @field attributeBuild CTIEBaseDTO|CTIEAttributeBuildDTO Attribute build configuration data
--- @field attributes CTIEBaseDTO|CTIEAttributesDTO Character attribute values data
--- @field career CTIEBaseDTO|CTIECareerDTO Character career/background data
--- @field characterFeatures CTIEBaseDTO|CTIECharacterFeaturesDTO Character features data
--- @field class CTIEBaseDTO|CTIEClassDTO Character class data
--- @field culture CTIEBaseDTO|CTIECultureDTO Character culture data
--- @field innateActivatedAbilities CTIEBaseDTO|CTIEInnateActivatedAbilitiesDTO Innate abilities data
--- @field kit CTIEBaseDTO|CTIEKitDTO Character kit data
--- @field resistances CTIEBaseDTO|CTIEResistancesDTO Character resistances data
--- @field characterType CTIEBaseDTO|CTIELookupTableDTO Lookup Key
--- @field complication CTIEBaseDTO|CTIELookupTableDTO Lookup Key
CTIECharacterDTO = RegisterGameType("CTIECharacterDTO", "CTIEBaseDTO")
CTIECharacterDTO.__index = CTIECharacterDTO

--- Creates a new character DTO instance with all component DTOs initialized.
--- @return CTIEBaseDTO|CTIECharacterDTO instance The new character DTO instance
function CTIECharacterDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("ancestry", CTIEAncestryDTO:new())
    instance:_setProp("attributes", CTIEAttributesDTO:new())
    instance:_setProp("career", CTIECareerDTO:new())
    instance:_setProp("class", CTIEClassDTO:new())
    instance:_setProp("culture", CTIECultureDTO:new())
    instance:_setProp("kit", CTIEKitDTO:new())
    instance:_setProp("characterType", CTIELookupTableDTO:new())
    instance:_setProp("complication", CTIELookupTableDTO:new())
    return instance
end

--- Gets the character ancestry data.
--- @return CTIEAncestryDTO ancestry The ancestry DTO
function CTIECharacterDTO:Ancestry()
    return self:_getProp("ancestry")
end

--- Gets the character attribute build configuration.
--- @return CTIEAttributeBuildDTO attributeBuild The attribute build DTO
function CTIECharacterDTO:AttributeBuild()
    return self:_getProp("attributeBuild")
end

--- Gets the character attribute values.
--- @return CTIEAttributesDTO attributes The attributes DTO
function CTIECharacterDTO:Attributes()
    return self:_getProp("attributes")
end

--- Gets the character career information.
--- @return CTIECareerDTO career The career DTO
function CTIECharacterDTO:Career()
    return self:_getProp("career")
end

--- Gets the character features data.
--- @return CTIECharacterFeaturesDTO characterFeatures The character features DTO
function CTIECharacterDTO:CharacterFeatures()
    return self:_getProp("characterFeatures")
end

--- Gets the character class information.
--- @return CTIEClassDTO class The class DTO
function CTIECharacterDTO:Class()
    return self:_getProp("class")
end

--- Gets the character culture data.
--- @return CTIECultureDTO culture The culture DTO
function CTIECharacterDTO:Culture()
    return self:_getProp("culture")
end

--- Gets the character innate activated abilities.
--- @return CTIEInnateActivatedAbilitiesDTO innateActivatedAbilities The innate activated abilities DTO
function CTIECharacterDTO:InnateActivatedAbilities()
    return self:_getProp("innateActivatedAbilities")
end

--- Gets the character kit data.
--- @return CTIEKitDTO kit The kit DTO
function CTIECharacterDTO:Kit()
    return self:_getProp("kit")
end

--- Gets the character resistances data.
--- @return CTIEResistancesDTO resistances The resistances DTO
function CTIECharacterDTO:Resistances()
    return self:_getProp("resistances")
end

--- Gets the character type lookup data.
--- @return CTIELookupTableDTO characterType The character type lookup DTO
function CTIECharacterDTO:CharacterType()
    return self:_getProp("characterType")
end

--- Gets the character complication lookup data.
--- @return CTIELookupTableDTO complication The complication lookup DTO
function CTIECharacterDTO:Complication()
    return self:_getProp("complication")
end
