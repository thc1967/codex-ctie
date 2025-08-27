local writeDebug = CTIEUtils.writeDebug

--- Imports selected features back into levelChoices format for Codex character data.
--- Matches selected features against available feature definitions and resolves GUIDs.
--- @class CTIELevelChoiceImporter
--- @field selectedFeaturesDTO CTIESelectedFeaturesDTO|CTIEBaseDTO The features selected on the import character
--- @field availableFeatures table The features available for the item we're processing
--- @field levelChoices table The list we'll return
CTIELevelChoiceImporter = RegisterGameType("CTIELevelChoiceImporter")
CTIELevelChoiceImporter.__index = CTIELevelChoiceImporter

--- Creates a new level choice importer and processes the selected features.
--- @param selectedFeaturesDTO CTIESelectedFeaturesDTO The selected features to import
--- @param availableFeatures table The list of available feature definitions
--- @return table levelChoices The levelChoices structure with feature GUIDs as keys
function CTIELevelChoiceImporter:new(selectedFeaturesDTO, availableFeatures)
    writeDebug("LEVELCHOICEIMPORTER:: NEW:: %s", json(availableFeatures))
    
    local instance = setmetatable({}, self)
    instance.selectedFeaturesDTO = selectedFeaturesDTO
    instance.availableFeatures = availableFeatures or {}
    instance.levelChoices = {}

    instance:_processSelectedFeatures()
    return instance.levelChoices
end

--- Processes all selected features and builds the levelChoices structure.
--- @private
function CTIELevelChoiceImporter:_processSelectedFeatures()
    local allFeatures = self.selectedFeaturesDTO:GetAllFeatures()

    for _, selectedFeature in pairs(allFeatures) do
        local matchedFeature = self:_findMatchingFeature(selectedFeature, self.availableFeatures)
        if matchedFeature then
            self:_addToLevelChoices(matchedFeature.guid, selectedFeature)
        else
            writeDebug("LEVELCHOICEIMPORTER:: No match found for choiceId: %s", selectedFeature:GetChoiceId() or "nil")
        end
    end
end

--- Recursively searches for a feature that matches the selected feature.
--- @param selectedFeature CTIESelectedFeatureDTO The selected feature to match
--- @param featureList table The list of features to search through
--- @return table|nil matchedFeature The matching feature or nil if not found
--- @private
function CTIELevelChoiceImporter:_findMatchingFeature(selectedFeature, featureList)
    writeDebug("LEVELCHOICEIMPORTER:: FINDMATCHINGFEATURE:: %s", selectedFeature:GetChoiceType())

    for _, feature in pairs(featureList) do
        -- Rule 1: Direct choiceId match
        writeDebug("LEVELCHOICEIMPORTER:: FINDMATCHINGFEATURE:: RULE1:: [%s] [%s]", selectedFeature:GetChoiceId(), feature.guid)
        if selectedFeature:GetChoiceId() and feature.guid == selectedFeature:GetChoiceId() then
            writeDebug("LEVELCHOICEIMPORTER:: FINDMATCHINGFEATURE:: MATCH!")
            return feature
        end

        -- Rule 2 & 3: choiceType matches typeName and categories check
        if self:_choiceTypeMatches(selectedFeature:GetChoiceType(), feature.typeName) then
            if self:_categoriesMatch(selectedFeature:GetCategories(), feature.categories) then
                return feature
            end
        end

        -- Recursively search nested features
        writeDebug("LEVELCHOICEIMPORTER:: FEATURES?:: %s", feature.name)
        local features = feature:try_get("features")
        if features then
            local nestedMatch = self:_findMatchingFeature(selectedFeature, features)
            if nestedMatch then
                return nestedMatch
            end
        end
    end

    return nil
end

--- Checks if choice type matches feature type name (case-insensitive).
--- @param choiceType string The choice type from selected feature
--- @param typeName string The type name from feature definition
--- @return boolean matches True if types match
--- @private
function CTIELevelChoiceImporter:_choiceTypeMatches(choiceType, typeName)
    if not choiceType or not typeName then
        return false
    end
    return string.lower(choiceType) == string.lower(typeName)
end

--- Checks if categories match between selected feature and feature definition.
--- @param selectedCategories table|nil Categories from selected feature
--- @param featureCategories table|nil Categories from feature definition
--- @return boolean matches True if categories match or selected has no categories
--- @private
function CTIELevelChoiceImporter:_categoriesMatch(selectedCategories, featureCategories)
    -- No categories on selected feature = always match
    if not selectedCategories then
        return true
    end
    
    -- Selected has categories but feature doesn't = no match
    if not featureCategories then
        return false
    end
    
    -- Check for exact category match
    for key, value in pairs(selectedCategories) do
        if key ~= "_luaTable" and featureCategories[key] ~= value then
            return false
        end
    end
    
    for key, value in pairs(featureCategories) do
        if key ~= "_luaTable" and selectedCategories[key] ~= value then
            return false
        end
    end
    
    return true
end

--- Adds a matched feature to the levelChoices structure with resolved selection GUIDs.
--- @param featureGuid string The GUID of the matched feature
--- @param selectedFeature CTIESelectedFeatureDTO The selected feature containing selections
--- @private
function CTIELevelChoiceImporter:_addToLevelChoices(featureGuid, selectedFeature)
    local selectionGuids = {}
    local selections = selectedFeature:GetSelections()
    
    for _, selection in pairs(selections) do
        local resolvedGuid = self:_resolveSelectionGuid(selection)
        if resolvedGuid then
            table.insert(selectionGuids, resolvedGuid)
        end
    end
    
    if #selectionGuids > 0 then
        self.levelChoices[featureGuid] = selectionGuids
        writeDebug("LEVELCHOICEIMPORTER:: Added %d selections for feature %s", #selectionGuids, featureGuid)
    end
end

--- Resolves a selection's GUID by verifying it against the table data.
--- @param selection CTIELookupTableDTO The selection to resolve
--- @return string|nil resolvedGuid The verified GUID or nil if not found
--- @private
function CTIELevelChoiceImporter:_resolveSelectionGuid(selection)
    local tableName = selection:GetTableName()
    local name = selection:GetName()
    local guid = selection:GetID()
    
    -- Use CTIEUtils to resolve the lookup record
    local resolvedGuid = CTIEUtils.ResolveLookupRecord(tableName, name, guid)
    
    if resolvedGuid then
        -- Verify the name matches what we expect
        local actualName = CTIEUtils.GetRecordName(tableName, resolvedGuid)
        if CTIEUtils.SanitizedStringsMatch(name, actualName) then
            return resolvedGuid
        else
            writeDebug("LEVELCHOICEIMPORTER:: Name mismatch for GUID %s: expected '%s', got '%s'", 
                     resolvedGuid, name, actualName)
        end
    end
    
    writeDebug("LEVELCHOICEIMPORTER:: Failed to resolve selection: table=%s, name=%s, guid=%s", 
             tableName or "nil", name or "nil", guid or "nil")
    return nil
end



-- --- CTIELevelChoiceImporter handles the import of character feature choices and level-based selections.
-- --- This class processes exported feature choice data, resolving lookup records and feature references
-- --- back to valid Codex game object GUIDs, then applies these selections to the destination character's
-- --- level choice system for proper game functionality.
-- --- @class CTIELevelChoiceImporter
-- --- @field destinationCharacter table The destination character object in the Codex system
-- CTIELevelChoiceImporter = RegisterGameType("CTIELevelChoiceImporter")
-- CTIELevelChoiceImporter.__index = CTIELevelChoiceImporter

-- local writeDebug = CTIEUtils.writeDebug
-- local writeLog = CTIEUtils.writeLog
-- local STATUS = CTIEUtils.STATUS

-- --- Creates a new CTIELevelChoiceImporter instance for importing feature choice data.
-- --- @param destinationCharacter table The destination character object in the Codex system
-- --- @return CTIELevelChoiceImporter instance The new importer instance
-- function CTIELevelChoiceImporter:new(destinationCharacter)
--     local instance = setmetatable({}, self)
--     instance.destinationCharacter = destinationCharacter
--     return instance
-- end

-- --- Imports feature choices and resolves them to valid game object GUIDs.
-- --- Processes each feature's selected choices, resolving lookup records through appropriate table lookups
-- --- or feature record matching. Successfully resolved choices are applied to the destination character's
-- --- level choice system, maintaining the original choice structure and keys.
-- --- @param selectedFeatures table The exported feature choices organized by feature GUID
-- --- @param availableFeatures? table The available feature options for resolving feature record references
-- function CTIELevelChoiceImporter:Import(selectedFeatures, availableFeatures)
--     writeDebug("LEVELCHOICEIMPORTER:: IMPORT:: START::")
--     writeLog("Feature Choices starting.", STATUS.INFO, 1)

--     for featureGuid, choices in pairs(selectedFeatures) do
--         writeDebug("LEVELCHOICEIMPORTER:: Processing feature GUID: %s", featureGuid)

--         local cleanChoices = {}

--         for choiceKey, choiceData in pairs(choices) do
--             writeDebug("LEVELCHOICEIMPORTER:: Processing choice %s", choiceKey)

--             local resolvedGuid = nil
--             if choiceData.tableName == CTIEUtils.FEATURE_TABLE_MARKER then
--                 resolvedGuid = CTIEUtils.ResolveFeatureRecord(availableFeatures, choiceData)
--             else
--                 resolvedGuid = CTIEUtils.ResolveLookupRecord(choiceData.tableName, choiceData.name, choiceData.guid)
--             end
--             if resolvedGuid and resolvedGuid ~= "" then
--                 cleanChoices[choiceKey] = resolvedGuid
--                 writeLog(string.format("Adding [%s] entry [%s]", choiceData.tableName, choiceData.name), STATUS.IMPL)
--                 writeDebug("LEVELCHOICEIMPORTER:: Resolved %s to %s", choiceData.name, resolvedGuid)
--             end
--         end

--         if next(cleanChoices) then
--             local lc = self.destinationCharacter:GetLevelChoices()
--             lc[featureGuid] = cleanChoices
--         end
--     end

--     writeLog("Feature Choices complete.", STATUS.INFO, -1)
--     writeDebug("LEVELCHOICEIMPORTER:: IMPORT:: COMPLETE::")
-- end

-- function CTIELevelChoiceImporter:ImportUnkeyed(selectedFeatures, availableFeatures)

--     local lc = self.destinationCharacter:GetLevelChoices()
--     writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: START:: %s", json(lc))
--     writeLog("Unkeyed Feature Choices starting.", STATUS.INFO, 1)

--     for _, choices in pairs(selectedFeatures) do
--         for _, choice in ipairs(choices) do
--             writeLog(string.format("Found Choice [%s].", choice.name), STATUS.INFO)

--             if choice.tableName == CTIEUtils.FEATURE_TABLE_MARKER then
--                 local foundFeature = false
--                 for _, feature in pairs(availableFeatures) do
--                     writeDebug(string.format("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: FEATURE:: [%s]", feature.name))

--                     if feature.typeName == "CharacterFeatureChoice" then
--                         local featureGuid = feature.guid
--                         for _, option in pairs(feature.options) do
--                             local nameMatch = CTIEUtils.SanitizedStringsMatch(option.name, choice.name)
--                             writeDebug(string.format("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: FEATURE:: OPTION:: [%s] VS [%s]: %s", option.name, choice.name, nameMatch))
--                             if nameMatch then
--                                 writeLog(string.format("Adding Ancestry Feature [%s] to character.", choice.name), STATUS.IMPL)
--                                 CTIEUtils.AppendTable(lc, featureGuid, option.guid)
--                                 foundFeature = true
--                                 break
--                             end
--                         end
--                         if foundFeature then break end
--                     end
--                 end
--             else
--                 writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: TABLE:: %s -> %s", choice.tableName, choice.name)
--                 writeLog(string.format("Found [%s]->[%s].", choice.tableName, choice.name), STATUS.INFO)
--                 local itemGuid = CTIEUtils.ResolveLookupRecord(choice.tableName, choice.name, choice.guid)
--                 local featureType = CTIEUtils.TableNameToChoiceType(choice.tableName):lower()
--                 writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: GUID:: %s TYPE:: %s", itemGuid, featureType)
--                 if itemGuid and #itemGuid and featureType and #featureType then
--                     writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: AVAILABLEFEATURES:: %s", json(availableFeatures))
--                     for _, feature in pairs(availableFeatures) do
--                         writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: AVAILABLEFEATURE:: %s", json(feature))
--                         if featureType == string.lower(feature.typeName) then
--                             -- TODO: May need a category check for culture?
--                             writeLog(string.format("Adding [%s]->[%s]", choice.tableName, choice.name), STATUS.IMPL)
--                             lc[feature.guid] = lc[feature.guid] or {}
--                             CTIEUtils.AppendTable(lc, feature.guid, itemGuid)
--                             break
--                         end
--                     end
--                 else
--                     writeLog(string.format("!!!! [%s]->[%s] not found in Codex.", choice.tableName, choice.name), STATUS.WARN)
--                 end
--             end
--         end
--     end

--     writeLog("Unkeyed Feature Choices complete.", STATUS.INFO, -1)
--     writeDebug("LEVELCHOICEIMPORTER:: IMPORTUNKEYED:: COMPLETE:: %s", json(lc))
-- end
