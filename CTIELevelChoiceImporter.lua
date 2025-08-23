--- CTIELevelChoiceImporter handles the import of character feature choices and level-based selections.
--- This class processes exported feature choice data, resolving lookup records and feature references
--- back to valid Codex game object GUIDs, then applies these selections to the destination character's
--- level choice system for proper game functionality.
--- @class CTIELevelChoiceImporter
--- @field destinationCharacter table The destination character object in the Codex system
CTIELevelChoiceImporter = RegisterGameType("CTIELevelChoiceImporter")
CTIELevelChoiceImporter.__index = CTIELevelChoiceImporter

local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local STATUS = CTIEUtils.STATUS

--- Creates a new CTIELevelChoiceImporter instance for importing feature choice data.
--- @param destinationCharacter table The destination character object in the Codex system
--- @return CTIELevelChoiceImporter instance The new importer instance
function CTIELevelChoiceImporter:new(destinationCharacter)
    local instance = setmetatable({}, self)
    instance.destinationCharacter = destinationCharacter
    return instance
end

--- Imports feature choices and resolves them to valid game object GUIDs.
--- Processes each feature's selected choices, resolving lookup records through appropriate table lookups
--- or feature record matching. Successfully resolved choices are applied to the destination character's
--- level choice system, maintaining the original choice structure and keys.
--- @param selectedFeatures table The exported feature choices organized by feature GUID
--- @param availableFeatures? table The available feature options for resolving feature record references
function CTIELevelChoiceImporter:Import(selectedFeatures, availableFeatures)
    writeDebug("LEVELCHOICEIMPORTER:: START")
    writeLog("Feature Choices starting.", STATUS.INFO, 1)

    for featureGuid, choices in pairs(selectedFeatures) do
        writeDebug("LEVELCHOICEIMPORTER:: Processing feature GUID: %s", featureGuid)

        local cleanChoices = {}

        for choiceKey, choiceData in pairs(choices) do
            writeDebug("LEVELCHOICEIMPORTER:: Processing choice %s", choiceKey)

            local resolvedGuid = nil
            if choiceData.tableName == "::FEATURE::" then
                resolvedGuid = CTIEUtils.ResolveFeatureRecord(availableFeatures, choiceData)
            else
                resolvedGuid = CTIEUtils.ResolveLookupRecord(choiceData.tableName, choiceData)
            end
            if resolvedGuid and resolvedGuid ~= "" then
                cleanChoices[choiceKey] = resolvedGuid
                writeLog(string.format("Adding [%s] entry [%s]", choiceData.tableName, choiceData.name), STATUS.IMPL)
                writeDebug("LEVELCHOICEIMPORTER:: Resolved %s to %s", choiceData.name, resolvedGuid)
            end
        end

        if next(cleanChoices) then
            local lc = self.destinationCharacter:GetLevelChoices()
            lc[featureGuid] = cleanChoices
        end
    end

    writeLog("Feature Choices complete.", STATUS.INFO, -1)
    writeDebug("LEVELCHOICEIMPORTER:: COMPLETE")
end
