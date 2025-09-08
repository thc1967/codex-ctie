--- Base class for all Data Transfer Objects.
--- @class CTIEBaseDTO
--- @property typeName string The name of the class of this object
CTIEBaseDTO = RegisterGameType("CTIEBaseDTO")
CTIEBaseDTO.__index = CTIEBaseDTO

local writeDebug = CTIEUtils.writeDebug

--- Creates a new Base DTO instance.
--- @return CTIEBaseDTO instance The new DTO instance
function CTIEBaseDTO:new()
    local instance = setmetatable({}, self)
    return instance
end

--- Sets a property value in the DTO with intelligent merging for existing CTIE DTO objects.
--- @param propName string The name of the property to set
--- @param value any The value to store
--- @return CTIEBaseDTO self Returns self for method chaining
function CTIEBaseDTO:_setProp(propName, value)
    writeDebug("BASEDTO:: SETPROP:: TYPE:: %s property:: %s", self.typeName, propName)
    self[propName] = value
    return self
end

--- Retrieves a property value from the DTO's data table (private method).
--- @param propName string The name of the property to retrieve
--- @return any|nil value The stored value or nil if property doesn't exist
function CTIEBaseDTO:_getProp(propName)
    return self:try_get(propName)
end

--- Converts table data to DTO instance using embedded class names.
--- @param data table The table data with typeName propertys
--- @return CTIEBaseDTO|table|nil instance The populated DTO instance or raw data
function CTIEBaseDTO:_fromTable(data)
    writeDebug("BASEDTO:: FROMTABLE:: START:: SELF:: %s", json(self))

    for propName, _ in pairs(self) do
        self:_setProp(propName, data[propName] or self[propName])
    end

    writeDebug("BASEDTO:: FROMTABLE:: %s", json(self))
    return self
end
