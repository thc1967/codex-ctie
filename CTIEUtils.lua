--- CTIEUtils provides utility functions and centralized services for the CTIE character import/export system.
--- This class serves as the foundation for all CTIE operations, offering logging infrastructure with debug and verbose modes,
--- string manipulation and validation utilities, game data table lookups with fallback mechanisms, and specialized
--- record creation/resolution functions for handling the translation between Codex game objects and serializable JSON data.
---
--- Key functionality includes:
--- - Debug and verbose logging with hierarchical indentation and color-coded status messages
--- - String sanitization, GUID validation, and fuzzy name matching for data resolution
--- - Game table lookups with both direct database queries and import system fallbacks
--- - Lookup record creation for database-backed objects (races, classes, skills, etc.)
--- - Feature record handling for option-based selections that don't exist in database tables
--- - Character export orchestration with validation, file generation, and user feedback
--- - Table manipulation utilities for merging configuration and data structures
---
--- The class maintains global state for debug and verbose modes, and provides a consistent logging
--- interface used throughout all CTIE import and export operations for progress tracking and error reporting.
--- @class CTIEUtils
CTIEUtils = RegisterGameType("CTIEUtils")
CTIEUtils.__index = CTIEUtils

local CTIE_DEBUG = true
local CTIE_VERBOSE = true

local TABLE_NAME_CHOICE_TYPE_MAP = {
    [Language.tableName] = "CharacterLanguageChoice",
    [Skill.tableName] = "CharacterSkillChoice",
}

--- Marker used in lookup records to identify features that exist in option lists rather than database tables
CTIEUtils.FEATURE_TABLE_MARKER = "::FEATURE::"

local CHOICE_TYPE_TO_TABLE_NAME_MAP = {
    ["CharacterDeityChoice"] = Deity.tableName,
    ["CharacterFeatChoice"] = CharacterFeat.tableName,
    ["CharacterFeatureChoice"] = CTIEUtils.FEATURE_TABLE_MARKER,
    ["CharacterLanguageChoice"] = Language.tableName,
    ["CharacterSkillChoice"] = Skill.tableName,
    ["CharacterSubclassChoice"] = "subclasses",
}

--- Sets the debug mode state.
--- @param v boolean The debug mode state to set
function CTIEUtils.SetDebugMode(v)
    CTIE_DEBUG = v
end

--- Toggles the debug mode between enabled and disabled.
function CTIEUtils.ToggleDebugMode()
    CTIE_DEBUG = not CTIE_DEBUG
end

--- Sets the verbose mode state.
--- @param v boolean The verbose mode state to set
function CTIEUtils.SetVerboseMode(v)
    CTIE_VERBOSE = v
end

--- Toggles the verbose mode between enabled and disabled.
function CTIEUtils.ToggleVerboseMode()
    CTIE_VERBOSE = not CTIE_VERBOSE
end

--- Returns whether verbose mode is currently enabled.
--- @return boolean verbose True if verbose mode is active, false otherwise
function CTIEUtils.inVerboseMode()
    return CTIE_VERBOSE
end

--- Returns whether debug mode is currently enabled.
--- @return boolean debug `true` if debug mode is active; `false` otherwise.
function CTIEUtils.inDebugMode()
    return CTIE_DEBUG
end

--- Writes a debug message to the debug log, if we're in debug mode
--- Suports param list like `string.format()`
--- @param fmt string Text to write
--- @param ...? string Tags for filling in the `fmt` string
function CTIEUtils.writeDebug(fmt, ...)
    if CTIE_DEBUG and fmt and #fmt > 0 then
        print("CTIE::", string.format(fmt, ...))
    end
end

--- Status flags for `CTIEUtils.writeLog()`
--- These control both logging behavior and text coloring
CTIEUtils.STATUS = {
    INFO  = "#aaaaaa",
    ERROR = "#aa0000",
    IMPL  = "#00aaaa",
    GOOD  = "#00aa00",
    WARN  = "#ff8c00",
}

--- Retrieves the line number from the call stack at a given level.
-- Useful for logging or debugging purposes.
--- @param level number (optional) The stack level to inspect. Defaults to 2 (the caller of this function).
--- @return number line The line number in the source file at the specified call stack level.
function CTIEUtils.curLine(level)
    level = level or 2
    return debug.getinfo(level, "l").currentline
end

--- Tracks the current indentation level for activity log messages.
--- This value is used to format output written to the user-facing log (not debug output),
--- allowing nested or hierarchical operations to visually reflect structure.
--- It is modified by logging functions to increase or decrease indentation as needed.
CTIEUtils.indentLevel = 0

--- Writes a formatted message to the log with optional status and indentation.
--- Applies color based on status and prepends indentation for nested output.
--- Typically indent at the start of a function and outdent at the end.
--- Indentation level is tracked globally and adjusted based on the `indent` value:
---   - A positive indent increases the level *after* the current message.
---   - A negative indent decreases the level *before* the current message.
---
--- @param message string The message to log.
--- @param status? string (optional) The status color code from CTIEUtils.STATUS (default: INFO).
--- @param indent? number (optional) A relative indent level (e.g., 1 to increase, -1 to decrease).
function CTIEUtils.writeLog(message, status, indent)
    status = status or CTIEUtils.STATUS.INFO
    indent = indent or 0

    if CTIE_VERBOSE or status ~= CTIEUtils.STATUS.INFO then
        -- Apply negative indent before logging
        if indent < 0 then CTIEUtils.indentLevel = math.max(0, CTIEUtils.indentLevel + indent) end

        -- Prepend caller's line number for warnings and errors
        if status == CTIEUtils.STATUS.WARN or status == CTIEUtils.STATUS.ERROR then
            message = string.format("%s (line %d)", message, CTIEUtils.curLine(3))
        end

        local indentPrefix = string.rep(" ", 2 * math.max(0, CTIEUtils.indentLevel))
        local indentedMessage = string.format("%s%s", indentPrefix, message)
        local formattedMessage = string.format("<color=%s>%s</color>", status, indentedMessage)

        import:Log(formattedMessage)

        -- Apply positive indent after logging
        if indent > 0 then CTIEUtils.indentLevel = CTIEUtils.indentLevel + indent end
    end
end

--- Compares two strings for equality after sanitizing and normalizing them.
--- This function removes special characters, trims whitespace, and converts both
--- strings to lowercase before comparison. Useful for fuzzy string matching where
--- formatting differences should be ignored.
--- @param s1 string|nil The first string to compare (nil treated as empty string)
--- @param s2 string|nil The second string to compare (nil treated as empty string)
--- @return boolean True if the sanitized strings match, false otherwise
function CTIEUtils.SanitizedStringsMatch(s1, s2)
    local function sanitize(s)
        s = s or ""
        return s:gsub("[^%w%s;:!@#%$%%^&*()%-+=%?,]", ""):trim()
    end

    local ns1 = string.lower(sanitize(s1))
    local ns2 = string.lower(sanitize(s2))

    return ns1 == ns2
end

--- Searches a game table for an item by name using both import system and fallback lookup.
--- First attempts to find the item using the import system's existing item lookup,
--- then falls back to manual table iteration with sanitized string matching.
--- @param tableName string The name of the Codex game table to search
--- @param name string The name of the item to find
--- @return string|nil id The GUID of the matching item if found, nil otherwise
--- @return table|nil row The complete item data if found, nil otherwise
function CTIEUtils.TableLookupFromName(tableName, name)
    local itemFound = import:GetExistingItem(tableName, name)
    if itemFound then return itemFound.id, itemFound end

    CTIEUtils.writeLog(string.format("TLFN fallthrough table [%s]->[%s].", tableName, name), CTIEUtils.STATUS.WARN)

    local t = dmhub.GetTable(tableName) or {}
    for id, row in pairs(t) do
        if not row:try_get("hidden", false) and CTIEUtils.SanitizedStringsMatch(row.name, name) then
            return id, row
        end
    end

    return nil, nil
end

--- Checks if a given ID exists in the specified game table.
--- @param tableName string The name of the Codex game table to check
--- @param id string The ID to look for in the table
--- @return boolean exists True if the ID exists in the table, false otherwise
function CTIEUtils.TableIdExists(tableName, id)
    local t = dmhub.GetTable(tableName)
    return t and t[id] ~= nil
end

--- Validates whether a string matches the standard GUID format.
--- Checks for the pattern: 8-4-4-4-12 hexadecimal characters with hyphens.
--- @param str string|nil The string to validate (nil or empty returns false)
--- @return boolean isGuid True if the string is a valid GUID format, false otherwise
function CTIEUtils.StringIsGuid(str)
    if not str or #str == 0 then
        return false
    end
    return string.match(str, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

--- Creates a standardized lookup record structure for import/export operations.
--- Provides a consistent format for storing table name, GUID, and name information
--- used throughout the CTIE system for data serialization and resolution.
--- @param tableName string|nil The Codex table name (defaults to empty string)
--- @param guid string|nil The GUID identifier (defaults to empty string)
--- @param name string|nil The display name (defaults to empty string)
--- @return table record The lookup record with tableName, guid, and name fields
function CTIEUtils.CreateLookupRecord(tableName, guid, name)
    return {
        tableName = tableName or "",
        guid = guid or "",
        name = name or ""
    }
end

--- Creates a feature record for features that exist in option lists rather than database tables.
--- Searches through the provided options list to find a feature matching the given GUID
--- and creates a lookup record with the special feature table name marker.
--- @param optionsList table The list of available feature options to search
--- @param guid string The GUID of the feature to create a record for
--- @return table record The feature lookup record with feature as table name
function CTIEUtils.MakeFeatureRecord(optionsList, guid)
    CTIEUtils.writeDebug("MAKEFEATURERECORD:: GUID:: %s", guid)

    if not optionsList or not guid then
        return CTIEUtils.CreateLookupRecord(CTIEUtils.FEATURE_TABLE_MARKER, guid, "")
    end

    -- Search through the feature list for the matching guid
    local name = ""
    for _, feature in pairs(optionsList) do
        CTIEUtils.writeDebug("MAKEFEATURERECORD:: %s %s", feature.guid, feature.name)
        if feature.guid == guid then
            name = feature.name or ""
            break
        end
    end

    CTIEUtils.writeDebug("MAKEFEATURERECORD:: DONE:: %s", name)
    return CTIEUtils.CreateLookupRecord(CTIEUtils.FEATURE_TABLE_MARKER, guid, name)
end

--- Resolves a feature record back to a valid feature GUID using the provided feature structure.
--- Searches through feature choices and their options to match either by GUID or name,
--- handling the special case of features that exist in option lists rather than database tables.
--- @param featureStructure table The available feature structure containing feature choices and options
--- @param featureRecord table The feature record containing guid and name to resolve
--- @return string guid The resolved feature GUID, or the original GUID if no match found
function CTIEUtils.ResolveFeatureRecord(featureStructure, featureRecord)
    CTIEUtils.writeDebug("RESOLVEFEATURERECORD:: %s", featureRecord and featureRecord.guid or "nil")

    if not featureRecord or not featureRecord.guid then
        return ""
    end

    if not featureStructure then
        return featureRecord.guid
    end

    -- Helper function to check a single feature
    local function checkFeature(feature, targetGuid, targetName)
        if feature.guid == targetGuid then
            return feature.guid
        end
        if targetName and #targetName > 0 and feature.name == targetName then
            return feature.guid
        end
        return nil
    end

    -- Search through the main feature structure
    for _, item in pairs(featureStructure) do
        if item.typeName == "CharacterFeatureChoice" and item.options then
            for _, option in pairs(item.options) do
                local result = checkFeature(option, featureRecord.guid, featureRecord.name)
                if result then
                    CTIEUtils.writeDebug("RESOLVEFEATURERECORD:: Found in feature choice: %s", option.name)
                    return result
                end
            end
        end
    end

    -- Return original GUID as fallback
    CTIEUtils.writeDebug("RESOLVEFEATURERECORD:: No match found, returning original GUID")
    return featureRecord.guid
end

--- Retrieves the display name for a record from a table using its GUID.
--- @param tableName string The name of the table containing the record
--- @param guid string The GUID of the record to look up
--- @return string name The display name of the record, or empty string if not found
function CTIEUtils.GetRecordName(tableName, guid)
    CTIEUtils.writeDebug("GETRECORDNAME:: TABLE:: %s GUID:: %s", tableName, guid)

    if not tableName or not guid then
        return ""
    end

    local table = dmhub.GetTable(tableName)
    if not table then
        return ""
    end

    local record = table[guid]
    return (record and record.name) and record.name or ""
end

--- Creates a lookup record by retrieving name information from a Codex game table.
--- Takes a table name and GUID, looks up the corresponding record to get the display name,
--- and creates a complete lookup record suitable for export operations.
--- @param tableName string The name of the Codex game table to query
--- @param guid string The GUID of the record to look up
--- @return table record The complete lookup record with table name, GUID, and resolved name
function CTIEUtils.MakeLookupRecord(tableName, guid)
    CTIEUtils.writeDebug("MAKELOOKUPRECORD:: TABLE:: %s GUID:: %s", tableName, guid)

    if not tableName or not guid then
        return CTIEUtils.CreateLookupRecord(tableName, guid, "")
    end
    local name = CTIEUtils.GetRecordName(tableName, guid)

    return CTIEUtils.CreateLookupRecord(tableName, guid, name)
end

--- Resolves a lookup record back to a valid GUID using table lookups and name matching.
--- Attempts resolution in priority order: direct GUID lookup, name-based matching, 
--- and finally returns the provided GUID if no table-based resolution succeeds.
--- @param tableName string|nil The name of the Codex game table to search
--- @param name string|nil The display name to match against table entries  
--- @param guid string|nil The GUID to lookup or return as fallback
--- @return string|nil guid The resolved GUID, or nil if all resolution attempts fail
function CTIEUtils.ResolveLookupRecord(tableName, name, guid)
    CTIEUtils.writeDebug("RESOLVELOOKUPRECORD:: table [%s] name [%s] guid [%s]", tableName or "nil", name or "nil", guid or "nil")

    -- If we have a table name and a guid, do the lookup by key. If found, return the guid.
    if tableName and guid then
        local table = dmhub.GetTable(tableName)
        if table and table[guid] then
            return guid
        end
    end
    CTIEUtils.writeDebug("RESOLVELOOKUPRECORD:: No Table or GUID not found in table.")

    -- If we have a table name and a name, do the lookup via TableLookupFromName. If found, return the guid.
    if tableName and name and #name > 0 then
        local id, _ = CTIEUtils.TableLookupFromName(tableName, name)
        if id then return id end
    end

    -- If we have a guid, return the guid.
    if guid then return guid end

    return nil
end

--- Maps choice types to table names.
--- @param choiceType string The choice type to look up
--- @return string tableName The choice type or empty string if not found
function CTIEUtils.ChoiceTypeToTableName(choiceType)
    return CHOICE_TYPE_TO_TABLE_NAME_MAP[choiceType] or ""
end

--- Maps table names to choice types via TABLE_NAME_CHOICE_TYPE_MAP lookup.
--- @param tableName string The table name to map
--- @return string choiceType The choice type or empty string if not found
function CTIEUtils.TableNameToChoiceType(tableName)
    return TABLE_NAME_CHOICE_TYPE_MAP[tableName] or ""
end

--- Merges all key-value pairs from source table into target table.
--- Overwrites any existing keys in the target table with values from the source table.
--- Modifies the target table in place and returns it for convenience.
--- @param target table The table to merge data into (modified in place)
--- @param source table The table to copy data from (unchanged)
--- @return table target The modified target table containing merged data
function CTIEUtils.MergeTables(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

--- Appends all elements from the source list to the target list.
--- Modifies the target list in place by adding all source elements at the end,
--- preserving the original order of both lists. Works with numeric-indexed arrays only.
--- @param target table The target list to append elements to (modified in place)
--- @param source table The source list containing elements to append (unchanged)
--- @return table target The modified target list containing original plus appended elements
function CTIEUtils.AppendList(target, source)
    if not target or not source then
        return target or {}
    end

    table.move(source, 1, #source, #target + 1, target)

    return target
end

--- Appends a value to a table at the specified key, creating the key's table if needed.
--- @param t table The target table to modify
--- @param k any The key where the value should be appended
--- @param v any The value to append
--- @return table The modified table
function CTIEUtils.AppendTable(t, k, v)
    t[k] = t[k] or {}
    table.insert(t[k], v)
    return t
end