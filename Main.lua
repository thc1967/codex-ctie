local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Sends a status message to the user via chat with optional color formatting.
--- Applies color coding for non-INFO status levels and sends the message using
--- the CTIE chat system with consistent styling and user targeting.
--- @param message string The message text to send to the user
--- @param status? string Optional status color code from CTIEUtils.STATUS (defaults to INFO)
local function statusToChat(message, status)
    local s = status or STATUS.INFO
    local m = message or ""
    if not m or #m == 0 then return end

    if s ~= STATUS.info then
        m = string.format("<color=%s>%s</color>", s, m)
    end

    SendTitledChatMessage(m, "ctie", "#e09c9c", dmhub.userid)
end

--- Exports the currently selected character token to a timestamped JSON file.
--- This high-level function orchestrates the complete export workflow including user validation,
--- character data extraction, file generation, and user feedback via chat messages.
--- Validates the selected token, creates an exporter instance, generates the export filename
--- with timestamp (or simplified name in debug mode), and provides status updates to the user.
--- @param token? Token Optional token to export (defaults to dmhub.currentToken)
--- @return nil This function has no return value; results are communicated via chat messages
function CTIEExport(token)
    local targetToken = token or dmhub.currentToken

    if not targetToken then
        statusToChat("No token selected.", STATUS.WARN)
        return
    end

    local exporter = CTIEExporter:new(targetToken)
    if not exporter then
        statusToChat("Selected token is not a hero.", STATUS.WARN)
        return
    end

    local characterData = exporter:Export()
    local jsonString = characterData:ToJSON()

    local writePath = "characters/" .. dmhub.gameid
    local exportFilename = string.format("%s_%s.json", characterData:GetCharacterName(), os.date("%Y%m%d%H%M%S"))
    if CTIEUtils.inDebugMode() then exportFilename = string.format("%s.json", characterData:GetCharacterName()) end
    local fullPath = dmhub.WriteTextFile(writePath, exportFilename, jsonString)

    if fullPath and #fullPath then
        statusToChat(string.format("Exported token as %s.", fullPath), STATUS.IMPL)
        writeDebug("Exported token as %s", fullPath)
    else
        statusToChat("Export failed.", STATUS.ERROR)
    end
end

function CTIEExport2(token)
    local targetToken = token or dmhub.currentToken

    if not targetToken then
        statusToChat("No token selected.", STATUS.WARN)
        return
    end

    local exporter = CTIEExporter:new(targetToken)
    if not exporter then
        statusToChat("Selected token is not a hero.", STATUS.WARN)
        return
    end

    local characterData = exporter:Export()
    local jsonString = characterData:ToJSON()

    local writePath = "characters/" .. dmhub.gameid
    local exportFilename = string.format("%s_%s.json", characterData:GetCharacterName(), os.date("%Y%m%d%H%M%S"))
    if CTIEUtils.inDebugMode() then exportFilename = string.format("%s.json", characterData:GetCharacterName()) end
    local fullPath = dmhub.WriteTextFile(writePath, exportFilename, jsonString)

    if fullPath and #fullPath then
        statusToChat(string.format("Exported token as %s.", fullPath), STATUS.IMPL)
        writeDebug("Exported token as %s", fullPath)
    else
        statusToChat("Export failed.", STATUS.ERROR)
    end
end

--- Handles CTIE chat commands including flag toggles and character export.
--- Use "d" to toggle debug logging and "v" to toggle verbose logging.
--- Use "export" to export the currently selected character token to JSON.
--- @param args string Optional command arguments: toggle flags ("d", "v") or "export"
Commands.ctie = function(args)
    -- Handle export command
    if args and string.lower(args):match("^%s*export%s*$") then
        CTIEExport2()
        return
    end

    -- Handle flag toggle
    if args and #args then
        if string.find(args:lower(), "d") then CTIEUtils.ToggleDebugMode() end
        if string.find(args:lower(), "v") then CTIEUtils.ToggleVerboseMode() end
    end
    statusToChat(string.format("<color=#00cccc>[d]ebug:</color> %s <color=#00cccc>[v]erbose:</color> %s", CTIEUtils.inDebugMode(), CTIEUtils.inVerboseMode()))
end

import.Register {
    id = "ctiecharacter",
    description = "Character from Codex Export",
    input = "plaintext",
    priority = 1200,
    text = function(importer, text)
        local characterData = CTIECharacterData:new()

        if characterData:FromJSON(text) then
            local ctieImporter = CTIEImporter:new(characterData)
            ctieImporter:Import()
        else
            writeLog("!!!! Invalid import file format!", CTIEUtils.STATUS.ERROR)
        end
    end
}
