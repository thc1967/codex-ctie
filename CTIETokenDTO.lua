local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character token-related information.
--- Contains visual representation and token-specific properties.
--- @class CTIETokenDTO
CTIETokenDTO = RegisterGameType("CTIETokenDTO", "CTIEBaseDTO")
CTIETokenDTO.__index = CTIETokenDTO

--- Creates a new token DTO instance.
--- @return CTIEBaseDTO|CTIETokenDTO instance The new token DTO instance
function CTIETokenDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    return instance
end

function CTIETokenDTO:SetName(name)
    return self:_setData("name", name)
end

function CTIETokenDTO:GetName()
    return self:_getData("name") or ""
end