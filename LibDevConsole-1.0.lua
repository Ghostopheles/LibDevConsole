assert(LibStub, "LibStub not found.");

local major, minor = "LibDevConsole", 1;

--- @class LibDevConsole
local LibDevConsole = LibStub:NewLibrary(major, minor);

local commandType = Enum.ConsoleCommandType;
local commandCategory = Enum.ConsoleCategory;
local colorType = Enum.ConsoleColorType;
local GetAllBaseCommands = _G.C_Console.GetAllCommands;

LibDevConsole.CommandType = commandType;
LibDevConsole.CommandCategory = commandCategory;
LibDevConsole.ConsoleColor = colorType;

---@param message string
---@param color? Enum.ConsoleColorType
--- Adds a message to the console window
function LibDevConsole.AddMessage(message, color)
    if not color or not tContains(colorType, color) then
        color = colorType.DefaultColor;
    end

    DeveloperConsole:AddMessage(message, colorType.DefaultColor);
end

---@param message string
--- Adds an error message (red) to the console window
function LibDevConsole.AddError(message)
    DeveloperConsole:AddMessage(message, colorType.ErrorColor);
end

---@param message string
--- Adds an echo (green message) to the console window
function LibDevConsole.AddEcho(message)
    DeveloperConsole:AddMessage(message, colorType.DefaultGreen);
end


-- under construction, nothing to see here
local function HelpCommandOverride(_, helpText)
    local helpColor = colorType.WarningColor;
    local self = LibDevConsole;
    if not helpText then
        local helpStr = "Console help categories:\n"
        local categories = {}
        for k, _ in pairs(self.CommandCategory) do
            tinsert(categories, k);
        end
        strjoin(", ", helpStr, unpack(categories));

        self.AddMessage(helpStr, helpColor)
    end
end

LibDevConsole.CustomCommandFunctions = { -- contains the function mappings of our custom commands
    libdev = function() LibDevConsole.AddMessage("Hello world!") return true; end, -- secret :p
};
LibDevConsole.CustomCommandInfo = {}; -- table where our custom commands will be kept
LibDevConsole.AllCommands = {}; -- table that will contain all base commands + our custom ones, for auto-complete

local BaseCommands = GetAllBaseCommands();

local function UpdateCommands()
    for _, command in ipairs(BaseCommands) do
        if not tContains(LibDevConsole.AllCommands, command) then
            tinsert(LibDevConsole.AllCommands, command);
        end
    end

    for _, command in ipairs(LibDevConsole.CustomCommandInfo) do
        if not tContains(LibDevConsole.AllCommands, command) then
            tinsert(LibDevConsole.AllCommands, command);
        end
    end
end

UpdateCommands();

local function GetAllCommandsOverride()
    return LibDevConsole.AllCommands;
end

_G.C_Console.GetAllCommands = GetAllCommandsOverride;

-- The return values from this are important - it returns two boolean values.
-- The first return indicates success, if false, the console will attempt to ConsoleExec the command itself.
-- Second return indicates whether or not the command should be added to the command history - should usually be true regardless of success.
local function CommandExecuteOverride(input)
    assert(not issecure(), "THIS SHOULD NOT BE SECURE??");
    local inputSplit = {strsplit(" ", input)};
    local command = inputSplit[1];
    local args = {select(2, unpack(inputSplit))};
    if LibDevConsole.CustomCommandFunctions[command] then
        -- if the command exists, we pcall it with any args
        local ok, result = pcall(LibDevConsole.CustomCommandFunctions[command], unpack(args));

        if not ok then
            LibDevConsole.AddError("Error executing " .. command .. ": " .. result);
            return false, true; -- returns false for failure, and true to add to history
        else
            -- returns the result of the command, or true, along with true to add to history
            return result or true, true;
        end
    else
        -- not our command - return false and let the console execute it
        return false, true;
    end
end

DeveloperConsole:SetExecuteCommandOverrideFunction(CommandExecuteOverride);

---@class ConsoleCommandInfo
--- the keys are important!
local ExampleCommandInfo = {
    help = "Say 'hello world!'", -- help text that shows up in the auto-complete window
    category = Enum.ConsoleCategory.Game, -- Enum.ConsoleCategory
    command = "myCommand", -- the command itself
    scriptParameters = "", -- not sure what this does
    scriptContents = "", -- this is a mystery too
    commandType = Enum.ConsoleCommandType.Script, -- Enum.ConsoleCommandType
    commandFunc = function() LibDevConsole.AddMessage("Hello World!") end, -- this is the function the command executes
}

--- Register a custom console command
---@param commandInfo ConsoleCommandInfo
---@return boolean
function LibDevConsole:RegisterCommand(commandInfo)
    local commandName = commandInfo.command;
    assert(type(commandName) == "string", "CommandInfo.command is not a string.");

    local commandFunc = commandInfo.commandFunc;
    assert(type(commandFunc) == "function", "CommandInfo.commandFunc is not a function.");
    commandInfo.commandFunc = nil; -- to clean up the return for the console auto-complete/search

    assert(type(commandInfo.help) == "string", "CommandInfo.help is not a valid string.");
    assert(tContains(Enum.ConsoleCommandType, commandInfo.commandType), "CommandInfo.commandType must be a valid ConsoleCommandType. (Enum.ConsoleCommandType)");
    assert(tContains(Enum.ConsoleCategory, commandInfo.category), "CommandInfo.category must be a valid ConsoleCategory. (Enum.ConsoleCategory)");

    if not commandInfo.scriptContents then
        commandInfo.scriptContents = "";
    end

    if not commandInfo.scriptParameters then
        commandInfo.scriptParameters = "";
    end

    if tContains(self.CustomCommandInfo, commandInfo) then
        LibDevConsole.AddMessage("Attempted to register existing command: " .. commandName);
        return false;
    end

    tinsert(self.CustomCommandInfo, commandInfo);
    self.CustomCommandFunctions[commandName] = commandFunc;

    UpdateCommands();
    self.AddMessage("Registered command: " .. commandName);
    return true;
end