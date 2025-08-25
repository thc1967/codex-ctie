local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character token-related information.
--- Contains visual representation and token-specific properties.
--- @class CTIETokenDTO
--- @field data table The data this DTO tracks
CTIETokenDTO = RegisterGameType("CTIETokenDTO", "CTIEBaseDTO")
CTIETokenDTO.__index = CTIETokenDTO

--- Creates a new token DTO instance.
--- @return CTIETokenDTO instance The new token DTO instance
function CTIETokenDTO:new()
    local instance = setmetatable({}, self)
    return instance
end

function CTIETokenDTO:_setData(fieldName, value)
    if fieldName and type(fieldName) == "string" then
        self.data[fieldName] = value
    end
    return self
end

function CTIETokenDTO:_getData(fieldName)
    return self.data[fieldName]
end

function CTIETokenDTO:SetName(name)
    return self:_setData("name", name)
end

function CTIETokenDTO:GetName()
    local name = self:_getData("name") or ""
    if CTIEUtils.inDebugMode() then name = "zzz" .. name end
    return name
end