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
    writeDebug("LEVELCHOICEIMPORTER:: IMPORT:: START::")
    writeLog("Feature Choices starting.", STATUS.INFO, 1)

    for featureGuid, choices in pairs(selectedFeatures) do
        writeDebug("LEVELCHOICEIMPORTER:: Processing feature GUID: %s", featureGuid)

        local cleanChoices = {}

        for choiceKey, choiceData in pairs(choices) do
            writeDebug("LEVELCHOICEIMPORTER:: Processing choice %s", choiceKey)

            local resolvedGuid = nil
            if choiceData.tableName == CTIEUtils.FEATURE_TABLE_MARKER then
                resolvedGuid = CTIEUtils.ResolveFeatureRecord(availableFeatures, choiceData)
            else
                resolvedGuid = CTIEUtils.ResolveLookupRecord(choiceData.tableName, choiceData.name, choiceData.guid)
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
    writeDebug("LEVELCHOICEIMPORTER:: IMPORT:: COMPLETE::")
end

function CTIELevelChoiceImporter:ImportUnkeyed(selectedFeatures, availableFeatures)

    local lc = self.destinationCharacter:GetLevelChoices()
    writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: START:: %s", json(lc))
    writeLog("Unkeyed Feature Choices starting.", STATUS.INFO, 1)

    for _, choices in pairs(selectedFeatures) do
        for _, choice in ipairs(choices) do
            writeLog(string.format("Found Choice [%s].", choice.name), STATUS.INFO)

            if choice.tableName == CTIEUtils.FEATURE_TABLE_MARKER then
                local foundFeature = false
                for _, feature in pairs(availableFeatures) do
                    writeDebug(string.format("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: FEATURE:: [%s]", feature.name))

                    if feature.typeName == "CharacterFeatureChoice" then
                        local featureGuid = feature.guid
                        for _, option in pairs(feature.options) do
                            local nameMatch = CTIEUtils.SanitizedStringsMatch(option.name, choice.name)
                            writeDebug(string.format("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: FEATURE:: OPTION:: [%s] VS [%s]: %s", option.name, choice.name, nameMatch))
                            if nameMatch then
                                writeLog(string.format("Adding Ancestry Feature [%s] to character.", choice.name), STATUS.IMPL)
                                CTIEUtils.AppendTable(lc, featureGuid, option.guid)
                                foundFeature = true
                                break
                            end
                        end
                        if foundFeature then break end
                    end
                end
            else
                writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: TABLE:: %s -> %s", choice.tableName, choice.name)
                writeLog(string.format("Found [%s]->[%s].", choice.tableName, choice.name), STATUS.INFO)
                local itemGuid = CTIEUtils.ResolveLookupRecord(choice.tableName, choice.name, choice.guid)
                local featureType = CTIEUtils.TableNameToChoiceType(choice.tableName):lower()
                writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: GUID:: %s TYPE:: %s", itemGuid, featureType)
                if itemGuid and #itemGuid and featureType and #featureType then
                    writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: AVAILABLEFEATURES:: %s", json(availableFeatures))
                    for _, feature in pairs(availableFeatures) do
                        writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: AVAILABLEFEATURE:: %s", json(feature))
                        if featureType == string.lower(feature.typeName) then
                            -- TODO: May need a category check for culture?
                            writeLog(string.format("Adding [%s]->[%s]", choice.tableName, choice.name), STATUS.IMPL)
                            lc[feature.guid] = lc[feature.guid] or {}
                            CTIEUtils.AppendTable(lc, feature.guid, itemGuid)
                            break
                        end
                    end
                else
                    writeLog(string.format("!!!! [%s]->[%s] not found in Codex.", choice.tableName, choice.name), STATUS.WARN)
                end
            end
        end
    end

    writeLog("Unkeyed Feature Choices complete.", STATUS.INFO, -1)
    writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: COMPLETE:: %s", json(lc))
end
