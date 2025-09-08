local writeDebug = CTIEUtils.writeDebug
local writeLog = CTIEUtils.writeLog
local fileLogger = CTIEUtils.FileLogger
local STATUS = CTIEUtils.STATUS

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
    fileLogger("import"):Log("LEVELCHOICEIMPORTER:: PROCESSSELECTEDFEATURES::"):Indent()
    local allFeatures = self.selectedFeaturesDTO:GetAllFeatures()

    for _, selectedFeature in pairs(allFeatures) do
        local choiceId = selectedFeature:GetChoiceId()

        -- Special handling for deity domain choices (artificial "-domains" entries)
        if choiceId and choiceId:match("%-domains$") then
            writeDebug("LEVELCHOICEIMPORTER:: Processing deity domains: %s", choiceId)
            local selectionGuids = {}
            local selections = selectedFeature:GetSelections()

            for _, selection in pairs(selections) do
                local resolvedGuid = CTIEUtils.ResolveLookupRecord(selection:GetTableName(), selection:GetName(), selection:GetID())
                if resolvedGuid then
                    table.insert(selectionGuids, resolvedGuid)
                end
            end

            if #selectionGuids > 0 then
                self.levelChoices[choiceId] = selectionGuids
                writeDebug("LEVELCHOICEIMPORTER:: Added %d domain selections for %s", #selectionGuids, choiceId)
            end
        else
            local matchedFeature = self:_findMatchingFeature(selectedFeature, self.availableFeatures)
            if matchedFeature then
                self:_addToLevelChoices(matchedFeature.guid, selectedFeature, matchedFeature)
            else
                writeDebug("LEVELCHOICEIMPORTER:: No match found for choiceId: %s", selectedFeature:GetChoiceId() or "nil")
            end
        end
    end

    fileLogger("import"):Outdent():Log("LEVELCHOICEIMPORTER:: PROCESSSELECTEDFEATURES:: COMPLETE")
end

--- Recursively searches for a feature that matches the selected feature.
--- @param selectedFeature CTIESelectedFeatureDTO The selected feature to match
--- @param featureList table The list of features to search through
--- @return table|nil matchedFeature The matching feature or nil if not found
--- @private
function CTIELevelChoiceImporter:_findMatchingFeature(selectedFeature, featureList)

    local selectedGuid = selectedFeature:GetChoiceId()

    for _, feature in pairs(featureList) do
        -- Rule 1: Direct choiceId match
        if selectedGuid then
            if  feature.guid == selectedGuid then
                return feature
            end
        else
            -- Rule 2 & 3: If we don't have a GUID in our source; choiceType matches typeName and categories check
            if self:_choiceTypeMatches(selectedFeature:GetChoiceType(), feature.typeName) then
                if self:_categoriesMatch(selectedFeature:GetCategories(), feature:try_get("categories")) then
                    return feature
                end
            end
        end

        -- Recursively search nested features
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
--- @param matchedFeature table|nil The matched feature (for feature option resolution)
--- @private
function CTIELevelChoiceImporter:_addToLevelChoices(featureGuid, selectedFeature, matchedFeature)
    local selectionGuids = {}
    local selections = selectedFeature:GetSelections()

    for _, selection in pairs(selections) do
        writeDebug("LEVELCHOICEIMPORTER::ADDTOLEVELCHOICES:: %s", selection:GetName())
        local resolvedGuid = self:_resolveSelectionGuid(selection, matchedFeature)
        if resolvedGuid then
            writeLog(string.format("Adding [%s] -> [%s].", selection:GetTableName(), selection:GetName()), STATUS.IMPL)
            table.insert(selectionGuids, resolvedGuid)
        end
    end

    if #selectionGuids > 0 then
        self.levelChoices[featureGuid] = selectionGuids
        writeDebug("LEVELCHOICEIMPORTER:: Added %d selections for feature %s", #selectionGuids, featureGuid)
    end
end

--- Resolves a selection's GUID by verifying it against table data or feature options.
--- @param selection CTIELookupTableDTO The selection to resolve
--- @param matchedFeature table|nil The matched feature containing options (for feature choices)
--- @return string|nil resolvedGuid The verified GUID or nil if not found
--- @private
function CTIELevelChoiceImporter:_resolveSelectionGuid(selection, matchedFeature)
    local tableName = selection:GetTableName()
    local name = selection:GetName()
    local guid = selection:GetID()

    -- Handle feature options (not database table records)
    if tableName == CTIEUtils.FEATURE_TABLE_MARKER and matchedFeature and matchedFeature.options then
        for _, option in pairs(matchedFeature.options) do
            -- Try GUID match first, then name match
            if option.guid == guid then
                return option.guid
            elseif CTIEUtils.SanitizedStringsMatch(option.name, name) then
                return option.guid
            end
        end
        writeDebug("LEVELCHOICEIMPORTER:: Feature option not found: name=%s, guid=%s", name or "nil", guid or "nil")
        return nil
    end

    -- Handle normal table lookups
    local resolvedGuid = CTIEUtils.ResolveLookupRecord(tableName, name, guid)

    if resolvedGuid then
        -- Verify the name matches what we expect
        local actualName = CTIEUtils.GetRecordName(tableName, resolvedGuid)
        if CTIEUtils.SanitizedStringsMatch(name, actualName) then
            return resolvedGuid
        else
            writeDebug("LEVELCHOICEIMPORTER:: Name mismatch for GUID %s: expected '%s', got '%s'", resolvedGuid, name, actualName)
        end
    end

    writeDebug("LEVELCHOICEIMPORTER:: Failed to resolve selection: table=%s, name=%s, guid=%s", tableName or "nil", name or "nil", guid or "nil")
    return nil
end
