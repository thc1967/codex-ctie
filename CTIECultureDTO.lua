--- Data Transfer Object for character cultural background.
--- Contains cultural traits, languages, and cultural bonuses.
--- @class CTIECultureDTO
--- @field language CTIEBaseDTO|CTIELookupTableDTO Lookup Key for the character's language
--- @field environment CTIEBaseDTO|CTIECultureAspectDTO Environment aspect with lookup and features
--- @field organization CTIEBaseDTO|CTIECultureAspectDTO Organization aspect with lookup and features
--- @field upbringing CTIEBaseDTO|CTIECultureAspectDTO Upbringing aspect with lookup and features
CTIECultureDTO = RegisterGameType("CTIECultureDTO", "CTIEBaseDTO")
CTIECultureDTO.__index = CTIECultureDTO

--- Creates a new culture DTO instance.
--- @return CTIEBaseDTO|CTIECultureDTO instance The new culture DTO instance
function CTIECultureDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("language", CTIELookupTableDTO:new())
    instance:_setProp("environment", CTIECultureAspectDTO:new())
    instance:_setProp("organization", CTIECultureAspectDTO:new())
    instance:_setProp("upbringing", CTIECultureAspectDTO:new())
    return instance
end

--- Gets the language lookup data.
--- @return CTIELookupTableDTO language The language lookup DTO
function CTIECultureDTO:Language()
    return self:_getProp("language")
end

--- Gets the environment aspect data.
--- @return CTIECultureAspectDTO environment The environment aspect DTO
function CTIECultureDTO:Environment()
    return self:_getProp("environment")
end

--- Gets the organization aspect data.
--- @return CTIECultureAspectDTO organization The organization aspect DTO
function CTIECultureDTO:Organization()
    return self:_getProp("organization")
end

--- Gets the upbringing aspect data.
--- @return CTIECultureAspectDTO upbringing The upbringing aspect DTO
function CTIECultureDTO:Upbringing()
    return self:_getProp("upbringing")
end
