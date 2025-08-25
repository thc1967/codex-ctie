local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for complete character mechanical data.
--- Aggregates all character systems including ancestry, classes, attributes, and features.
--- @class CTIECharacterDTO
CTIECharacterDTO = RegisterGameType("CTIECharacterDTO", "CTIEBaseDTO")
CTIECharacterDTO.__index = CTIECharacterDTO

--- Creates a new character DTO instance with all component DTOs initialized.
--- @return CTIEBaseDTO|CTIECharacterDTO instance The new character DTO instance
function CTIECharacterDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance.data = {
        ancestry = CTIEAncestryDTO:new(),
        attributeBuild = CTIEAttributeBuildDTO:new(),
        attributes = CTIEAttributesDTO:new(),
        career = CTIECareerDTO:new(),
        characterFeatures = CTIECharacterFeaturesDTO:new(),
        class = CTIEClassDTO:new(),
        culture = CTIECultureDTO:new(),
        innateActivatedAbilities = CTIEInnateActivatedAbilitiesDTO:new(),
        kit = CTIEKitDTO:new(),
        resistances = CTIEResistancesDTO:new(),
    }
    return instance
end