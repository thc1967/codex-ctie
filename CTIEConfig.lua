--- CTIEConfig provides centralized configuration for character import and export operations.
--- This module defines which properties should be transferred during export/import processes,
--- lookup table mappings for resolving GUIDs, and system-wide constants used by CTIE parsers and importers.
--- @class CTIEConfig
CTIEConfig = RegisterGameType("CTIEConfig")
CTIEConfig.__index = CTIEConfig

--- Standard character attribute names.
--- Defines the canonical order and naming for character attributes in import/export operations.
--- @type string[] Array of attribute identifiers: might, agility, intuition, presence, reason
CTIEConfig.attributes = { "mgt", "agl", "rea", "inu", "prs" }

--- Standard culture aspect names.
--- Defines the canonical order and naming for culture aspects in import/export operations.
--- @type string[] Array of culture aspects: environment, organization, upbringing.
CTIEConfig.cultureAspects = { "environment", "organization", "upbringing" }

--- Configuration settings for token-level data processing.
--- @type table Container for all token-related configuration options
CTIEConfig.token = {}

--- Defines which token properties should be copied verbatim during export and import operations.
--- Each property specifies export and import flags to control data flow direction.
--- Properties marked as export=true will be included in exported JSON files.
--- Properties marked as import=true will be restored when importing characters.
--- @type table<string, {export: boolean, import: boolean}> Map of property names to export/import flags
CTIEConfig.token.verbatim = {
    name = { export = true, import = true },
    anthem = { export = true, import = true },
    anthemVolume = { export = true, import = true },
    invisibleToPlayers = { export = true, import = true },
    namePrivate = { export = true, import = true },
    offTokenPortrait = { export = true, import = true },
    ownerId = { export = true, import = false },
    partyId = { export = true, import = false },
    popoutScale = { export = true, import = true },
    portrait = { export = true, import = true },
    portraitBackground = { export = true, import = true },
    portraitFrame = { export = true, import = true },
    portraitFrameBrightness = { export = true, import = true },
    portraitFrameHueShift = { export = true, import = true },
    portraitFrameSaturation = { export = true, import = true },
    portraitOffset = { export = true, import = false },
    portraitRibbon = { export = true, import = true },
    portraitZoom = { export = true, import = true },
    saddles = { export = true, import = true },
}

--- Configuration settings for character-level data processing.
--- @type table Container for all character-related configuration options
CTIEConfig.character = {}

--- Defines which character properties should be copied verbatim during export and import operations.
--- Each property specifies export and import flags to control data flow direction.
--- Properties marked as export=true will be included in exported JSON files.
--- Properties marked as import=true will be restored when importing characters.
--- @type table<string, {keyed: boolean, export: boolean, import: boolean}> Map of character property names to export/import flags
CTIEConfig.character.verbatim = {
    attributeBuild = { keyed = true, export = true, import = false },
    characterFeatures = { keyed = false, export = true, import = true },
    innateActivatedAbilities = { keyed = false, export = true, import = true },
    resistances = { keyed = false, export = true, import = true },
}

--- Maps character property names to their corresponding Codex database table names for GUID resolution.
--- Used by lookup record functions to resolve exported GUID/name pairs back to valid game objects during import.
--- Each entry associates a character property with the table name needed for CTIEUtils.ResolveLookupRecord operations.
--- @type table<string, {property: string, tableName: string}> Map of character property and table names
CTIEConfig.character.lookupRecords = {
    characterType = { property = "chartypeid", tableName = CharacterType.tableName },
    complication = { property = "complicationid", tableName = CharacterComplication.tableName },
}

