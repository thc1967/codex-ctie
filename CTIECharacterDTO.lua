local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

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
--- @field characterType CTIEBaseDTO|CTIELookupTableDTO Character type data
--- @field complication CTIEBaseDTO|CTIELookupTableDTO Character type data
CTIECharacterDTO = RegisterGameType("CTIECharacterDTO", "CTIEBaseDTO")
CTIECharacterDTO.__index = CTIECharacterDTO

--- Creates a new character DTO instance with all component DTOs initialized.
--- @return CTIEBaseDTO|CTIECharacterDTO instance The new character DTO instance
function CTIECharacterDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance.ancestry = CTIEAncestryDTO:new()
    instance.attributeBuild = CTIEAttributeBuildDTO:new()
    instance.attributes = CTIEAttributesDTO:new()
    instance.career = CTIECareerDTO:new()
    instance.characterFeatures = CTIECharacterFeaturesDTO:new()
    instance.class = CTIEClassDTO:new()
    instance.culture = CTIECultureDTO:new()
    instance.innateActivatedAbilities = CTIEInnateActivatedAbilitiesDTO:new()
    instance.kit = CTIEKitDTO:new()
    instance.resistances = CTIEResistancesDTO:new()
    instance.characterType = CTIELookupTableDTO:new()
    instance.complication = CTIELookupTableDTO:new()
    return instance
end
