local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for lookup table records.
--- Stores GUID, name, and table name for later record resolution.
--- @class CTIELookupTableDTO
CTIELookupTableDTO = RegisterGameType("CTIELookupTableDTO", "CTIEBaseDTO")
CTIELookupTableDTO.__index = CTIELookupTableDTO

--- Creates a new lookup table DTO instance.
--- @return CTIEBaseDTO|CTIELookupTableDTO instance The new lookup table DTO instance
function CTIELookupTableDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

--- Sets the table name for this lookup record.
--- @param tableName string The name of the table containing the record
--- @return CTIELookupTableDTO self Returns self for method chaining
function CTIELookupTableDTO:SetTableName(tableName)
    return self:_setProp("tableName", tableName)
end

--- Gets the table name for this lookup record.
--- @return string|nil tableName The table name, or nil if not set
function CTIELookupTableDTO:GetTableName()
    return self:_getProp("tableName")
end

--- Sets the display name for this lookup record.
--- @param name string The display name of the record
--- @return CTIELookupTableDTO self Returns self for method chaining
function CTIELookupTableDTO:SetName(name)
    return self:_setProp("name", name)
end

--- Gets the display name for this lookup record.
--- @return string|nil name The display name, or nil if not set
function CTIELookupTableDTO:GetName()
    return self:_getProp("name")
end

--- Sets the GUID for this lookup record.
--- @param guid string The GUID of the record
--- @return CTIELookupTableDTO self Returns self for method chaining
function CTIELookupTableDTO:SetID(guid)
    return self:_setProp("guid", guid)
end

--- Gets the GUID for this lookup record.
--- @return string|nil guid The GUID, or nil if not set
function CTIELookupTableDTO:GetID()
    return self:_getProp("guid")
end

--- Returns the lookup record as a plain table structure.
--- @return table lookupRecord The lookup record with guid, name, and tableName fields
function CTIELookupTableDTO:ToTable()
    return {
        guid = self:GetID() or "",
        name = self:GetName() or "",
        tableName = self:GetTableName() or ""
    }
end
