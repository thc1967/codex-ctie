local writeDebug = CTIEUtils.writeDebug

--- Base class for all Data Transfer Objects.
--- @class CTIEBaseDTO
--- @field typeName string The name of the class of this object
CTIEBaseDTO = RegisterGameType("CTIEBaseDTO")
CTIEBaseDTO.__index = CTIEBaseDTO

--- Creates a new Base DTO instance.
--- @return CTIEBaseDTO instance The new DTO instance
function CTIEBaseDTO:new()
    local instance = setmetatable({}, self)
    return instance
end

--- Sets a field value in the DTO with intelligent merging for existing CTIE DTO objects.
--- Handles three scenarios:
--- 1. Field doesn't exist - sets directly with DeepCopy for tables
--- 2. Field exists but isn't a CTIE DTO - replaces with new value  
--- 3. Field exists and is a CTIE DTO - recursively updates if value is table, logs debug error if not
--- @param fieldName string The name of the field to set
--- @param value any The value to store (tables are deep copied, CTIE DTOs are recursively updated)
--- @return CTIEBaseDTO self Returns self for method chaining
function CTIEBaseDTO:_setData(fieldName, value)
    writeDebug("SETDATA:: TYPE:: %s FIELD:: %s", self.typeName, fieldName)
    local existingValue = self:try_get(fieldName)

    -- If field doesn't exist, just set it
    if existingValue == nil then
        local v = value
        if type(v) == "table" then
            v = DeepCopy(value)
        end
        self[fieldName] = v
        return self
    end

    -- Field exists - check if it's a CTIE DTO object
    if not self:_isCTIEDTO(existingValue) then
        -- Not a CTIE DTO, just replace it
        local v = value
        if type(v) == "table" then
            v = DeepCopy(value)
        end
        self[fieldName] = v
        return self
    end

    -- Existing field is a CTIE DTO - recursively update if new value is a table
    if type(value) == "table" then
        for key, newValue in pairs(value) do
            existingValue:_setData(key, newValue)
        end
    else
        -- Error: attempting to destroy an existing DTO with non-table value
        writeDebug("CTIEBaseDTO:: SETDATA:: ERROR:: Attempt to destroy DTO %s : %s.", fieldName, existingValue.typeName)
    end

    return self
end

--- Retrieves a field value from the DTO's data table (private method).
--- @param fieldName string The name of the field to retrieve
--- @return any|nil value The stored value or nil if field doesn't exist
function CTIEBaseDTO:_getData(fieldName)
    return self:try_get(fieldName)
end

--- Converts token DTO to table format for JSON serialization.
--- @return table result The DTO's data as a serializable table
function CTIEBaseDTO:_toTable()
    local result = {
        __typeName = self.typeName or "CTIEBaseDTO",
    }
    for k, v in pairs(self) do
        if type(v) == "table" and v:try_get("_toTable") then
            result[k] = v:_toTable()
        else
            result[k] = v
        end
    end
    return result
end

--- Converts table data to DTO instance using embedded class names.
--- @param data table The table data with __typeName fields
--- @return CTIEBaseDTO|nil instance The populated DTO instance  
function CTIEBaseDTO:_fromTable(data)
    local className = data.__typeName or "CTIEBaseDTO"
    local classTable = _G[className]

    if not classTable then
        CTIEUtils.writeDebug("Unknown class: %s", className)
        return nil
    end

    local instance = classTable:new()

    for k, v in pairs(data) do
        if k ~= "__typeName" then
            if type(v) == "table" and v.__typeName then
                -- Recursively deserialize nested DTOs
                local nested = CTIEBaseDTO:_fromTable(v)
                if nested then
                    instance.data[k] = nested
                end
            else
                instance.data[k] = v
            end
        end
    end

    return instance
end

--- Checks if a value is a CTIE DTO object.
--- @param value any The value to check
--- @return boolean isCTIEDTO True if value is a CTIE DTO object
--- @private
function CTIEBaseDTO:_isCTIEDTO(value)
    if type(value) ~= "table" or not value.typeName then
        return false
    end

    local typeName = value.typeName
    return type(typeName) == "string" and 
           typeName:sub(1, 4) == "CTIE" and 
           typeName:sub(-3) == "DTO"
end
