local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character class information.
--- Contains class levels, features, and class-specific progression data.
--- @class CTIEClassDTO
--- @field classid CTIEClassDTO|CTIEBaseDTO Lookup key
--- @field level number The class level
--- @field selectedFeatures CTIEBaseDTO|CTIESelectedFeaturesDTO Selected features for the career
CTIEClassDTO = RegisterGameType("CTIEClassDTO", "CTIEBaseDTO")
CTIEClassDTO.__index = CTIEClassDTO

--- Constants for class level validation
local CLASS_LEVEL_MIN = 1
local CLASS_LEVEL_MAX = 10

--- Creates a new classes DTO instance.
--- @return CTIEBaseDTO|CTIEClassDTO instance The new classes DTO instance
function CTIEClassDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance:_setProp("classid", CTIELookupTableDTO:new())
    instance:_setProp("level", CLASS_LEVEL_MIN)
    instance:_setProp("selectedFeatures", CTIESelectedFeaturesDTO:new())
    return instance
end

--- Gets the class ID lookup data.
--- @return CTIELookupTableDTO classid The class ID lookup DTO
function CTIEClassDTO:GuidLookup()
    return self:_getProp("classid")
end

--- Gets the selected features data.
--- @return CTIESelectedFeaturesDTO selectedFeatures The selected features DTO
function CTIEClassDTO:SelectedFeatures()
    return self:_getProp("selectedFeatures")
end

--- Gets the class level with range validation.
--- Returns 1 if stored level is outside valid range (1-10).
--- @return number level The class level (1-10)
function CTIEClassDTO:GetLevel()
    local level = self:_getProp("level")
    if type(level) == "number" and level >= CLASS_LEVEL_MIN and level <= CLASS_LEVEL_MAX then
        return level
    end
    return CLASS_LEVEL_MIN
end

--- Sets the class level with validation.
--- Only accepts levels between 1 and 10 inclusive.
--- @param level number The class level to set (must be 1-10)
--- @return CTIEClassDTO self Returns self for method chaining
function CTIEClassDTO:SetLevel(level)
    if type(level) == "number" and level >= CLASS_LEVEL_MIN and level <= CLASS_LEVEL_MAX then
        return self:_setProp("level", level)
    end
    return self
end