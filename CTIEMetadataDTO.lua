--- Current CTIE file format version for metadata and compatibility checking.
local CTIE_VERSION = 1

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Data Transfer Object for character export/import metadata.
--- Contains version information, timestamps, and export source details.
--- @class CTIEMetadataDTO
--- @field version integer The file format version for this instance
--- @field exportTimestamp string|osdate The full time this instance was created
CTIEMetadataDTO = RegisterGameType("CTIEMetadataDTO", "CTIEBaseDTO")
CTIEMetadataDTO.__index = CTIEMetadataDTO

--- Creates a new metadata DTO instance with default values.
--- @return CTIEBaseDTO|CTIEMetadataDTO instance The new metadata DTO instance
function CTIEMetadataDTO:new()
    local instance = setmetatable(CTIEBaseDTO:new(), self)
    instance.data = {
        version = CTIE_VERSION,
        exportTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    return instance
end
