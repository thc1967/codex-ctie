--- Base class for all Data Transfer Objects.
--- @class CTIEBaseDTO
--- @field data table The data this object manages
CTIEBaseDTO = RegisterGameType("CTIEBaseDTO")
CTIEBaseDTO.__index = CTIEBaseDTO

--- Creates a new Base DTO instance.
--- @return CTIEBaseDTO instance The new DTO instance
function CTIEBaseDTO:new()
    local instance = setmetatable({}, self)
    instance.data = {}
    return instance
end

--- Converts token DTO to table format for JSON serialization.
--- @return table result The DTO's data as a serializable table
function CTIEBaseDTO:ToTable()
    local result = {}
    for k, v in pairs(self.data) do
        if type(v) == "table" and v.ToTable then
            result[k] = v:ToTable()
        else
            result[k] = v
        end
    end
    return result
end
