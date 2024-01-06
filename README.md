# LibDevConsole

A simple library to add custom commands to the built-in Developer Console. Requires [LibStub](https://www.curseforge.com/wow/addons/libstub).

## Usage

Add `LibDevConsole-1.0.lua` to your addon, either by downloading a packaged version from this repo, or by embedding `LibDevConsole-1.0.lua` into your own addon, then load it with a .toc/.xml file, and access it from your own code as follows:
```lua
local LibDevConsole = LibStub:GetLibrary("LibDevConsole");

local MyCommandInfo = {
    help = "Say 'hello world!'", -- help text that shows up in the auto-complete window
    category = Enum.ConsoleCategory.Game, -- Enum.ConsoleCategory
    command = "myCommand", -- the command itself
    scriptParameters = "", -- not sure what this does
    scriptContents = "", -- this is a mystery too
    commandType = Enum.ConsoleCommandType.Script, -- Enum.ConsoleCommandType
    commandFunc = function() LibDevConsole.AddMessage("Hello World!") end, -- this is the function the command executes
};

local success = LibDevConsole.RegisterCommand(MyCommandInfo);
```
