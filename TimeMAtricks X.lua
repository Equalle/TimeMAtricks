---@diagnostic disable: redundant-parameter

local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
MyHandle = select(4, ...)

-- PLUGIN STATE
local pluginAlive = nil
local pluginRunning = false
local pluginError = nil

local GMA, C, UI, XML

-- MODULE DEFINITIONS
-- Map: variable name -> { filename, embedded code }
local modules = {
  GMA = {
    file = "gma.lua",
    code = [[
  ]]
  },
  C = {
    file = "constants.lua",
    code = [[
]]
  },
  UI = {
    file = "ui.lua",
    code = [[
]]
  },
  XML = {
    file = "ui_xml.lua",
    code = [[
]]
  },
}

-- WRITE AND LOAD MODULES
local function import_modules()
  local pluginLibPath = GetPath(Enums.PathType.PluginLibrary)
  local devModulePath = 'C:\\Users\\Juri\\Desktop\\GrandMA3 Plugins\\TimeMAtricks with modules\\modules\\'
  -- local devModulePath = '/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks with modules/modules/'

  -- Create plugin-specific subfolder in plugin library
  local slash = package.config:sub(1, 1) -- Get OS-specific path separator
  local pluginFolder = "TimeMAtricks"
  local pluginModulePath = pluginLibPath .. slash .. pluginFolder .. slash

  -- Create directory if it doesn't exist
  local success = CreateDirectoryRecursive(pluginModulePath)
  if not success then
    ErrEcho("Failed to create module directory: %s", pluginModulePath)
  end

  -- Table to map module names to their variable assignments
  local moduleVars = {
    GMA = function(result) GMA = result end,
    C = function(result) C = result end,
    UI = function(result) UI = result end,
    XML = function(result) XML = result end,
    L = function(result) L = result end
  }

  for moduleName, moduleData in pairs(modules) do
    local fileName = "TM_" .. moduleData.file
    local pluginLibFile = pluginModulePath .. fileName

    -- First, try to load from development directory
    local devFilePath = devModulePath .. moduleData.file
    local devFile = io.open(devFilePath, "r")

    if devFile then
      -- Development file exists, read its content
      local devContent = devFile:read("*a")
      devFile:close()

      -- Copy dev file to plugin library
      local copyFile = io.open(pluginLibFile, "w")
      if copyFile then
        copyFile:write(devContent)
        copyFile:close()
        Echo("Copied dev module %s to plugin library", moduleData.file)
      else
        ErrEcho("Failed to copy dev module %s to plugin library", moduleData.file)
      end

      -- Load from plugin library (not dev directory)
      local success, result = pcall(dofile, pluginLibFile)
      if success then
        if moduleVars[moduleName] then
          moduleVars[moduleName](result)
        end
        Echo("Loaded module %s", pluginLibFile)
      else
        ErrEcho("Error loading module %s from plugin library: %s", pluginLibFile, result)
      end
    else
      -- Fall back to embedded module code and write to plugin library subfolder
      local file = io.open(pluginLibFile, "w")
      if file then
        file:write(moduleData.code)
        file:close()
        Echo("Written embedded module %s to plugin library", moduleName)

        -- Load the module
        local success, result = pcall(dofile, pluginLibFile)
        if success then
          if moduleVars[moduleName] then
            moduleVars[moduleName](result)
          end
        else
          Echo("Error loading module %s: %s", moduleName, result)
        end
      else
        Echo("Error writing module %s to file", moduleName)
      end
    end
  end
  C.echo()
  GMA.echo()
  UI.echo()
  XML.echo()
end

local function loop()
  pluginAlive = true
  coroutine.yield(1)
  -- Echo("LOOPING...")
end

local function kill_plugin()
end

local function main()
  if not pluginAlive then
    import_modules()
    if UI.is_valid_item(C.CMD_ICON_NAME, "cmdLN") then
      pluginAlive = true
    else
      pluginAlive = false
      UI.create_icon()
      if not DataPool(1).Macros:Find("TimeMAtricks Reset") then
        if not GMA.reset_macro() then
          ErrEcho("Failed to create reset macro")
        end
      end
    end
    signalTable.open_menu()
    local firstopen = GMA.get_globalV("TM_firststart") or nil
    if not firstopen then
      GMA.msgbox({
        title = "First Launch",
        message = "Press the Settings button at the top to configure the starting MAtricks pool number.",
        commands = { { value = 1, name = "Ok" } },
        icon = "QuestionMarkIcon",
        timeout = 10000,
        backColor = "Window.Plugins",
      })
      GMA.set_globalV("TM_firststart", true)
    end
    GMA.set_globalV("TM_firststart", true)
    Timer(loop, 0, 0, kill_plugin)
  else
    signalTable.open_menu()
  end
end

-- SIGNALTABLES
signalTable.open_menu = function()
  UI.open_menu()
end

signalTable.text = function(caller)
  Echo(caller.Content)
end

return main
