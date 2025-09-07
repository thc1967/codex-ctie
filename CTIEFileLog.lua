--- File logging utility for CTIE operations with indentation support.
--- Maintains log content in memory and writes complete file on each log operation.
--- @class CTIEFileLog
--- @field fileName string The name of the log file (without extension)
--- @field writePath string The directory path for log files
--- @field indentLevel number Current indentation level for log entries
--- @field logLines table Array of log line strings to write to file
CTIEFileLog = RegisterGameType("CTIEFileLog")
CTIEFileLog.__index = CTIEFileLog

--- Creates a new file logger instance.
--- @param fileName string|nil Optional file name without extension (defaults to "ctie")
--- @return CTIEFileLog instance The new file logger instance
function CTIEFileLog:new(fileName)
    local instance = setmetatable({}, self)
    instance.fileName = string.lower(fileName or "ctie") .. ".txt"
    instance.writePath = "logs/" .. dmhub.gameid
    instance.indentLevel = 0
    instance.logLines = {}
    return instance
end

--- Increases the indentation level by 1.
--- @return CTIEFileLog self Returns self for method chaining
function CTIEFileLog:Indent()
    self.indentLevel = self.indentLevel + 1
    return self
end

--- Decreases the indentation level by 1, minimum 0.
--- @return CTIEFileLog self Returns self for method chaining
function CTIEFileLog:Outdent()
    self.indentLevel = math.max(0, self.indentLevel - 1)
    return self
end

--- Logs a formatted message with current indentation and writes to file.
--- @param fmt string Format string for the log message
--- @param ... any Additional arguments for string formatting
--- @return CTIEFileLog self Returns self for method chaining
function CTIEFileLog:Log(fmt, ...)
    local message = string.format(fmt, ...)
    local indentPrefix = string.rep("  ", self.indentLevel)
    local indentedMessage = indentPrefix .. message

    table.insert(self.logLines, indentedMessage)
    self:Write()

    return self
end

--- Clears the log content and writes empty file.
--- @return CTIEFileLog self Returns self for method chaining
function CTIEFileLog:Clear()
    self.logLines = {}
    self:Write()
    return self
end

--- Writes the current log content to file.
--- @private
function CTIEFileLog:Write()
    local fileContents = table.concat(self.logLines, "\n")
    local fullPath = dmhub.WriteTextFile(self.writePath, self.fileName, fileContents)
    -- CTIEUtils.writeDebug("FILELOGGER:: WRITE:: RESULT:: %s", fullPath)
end