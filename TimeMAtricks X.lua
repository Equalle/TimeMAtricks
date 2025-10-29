---@diagnostic disable: redundant-parameter

-- local pluginName = select(1, ...)
-- local componentName = select(2, ...)
SignalTable = select(3, ...)
MyHandle = select(4, ...)

-- PLUGIN STATE
local pluginAlive = nil
PluginRunning = false
PluginError = nil

-------------
-- MODULES --
-------------

local GMA, C, UI, XML, S, O

-- MODULE DEFINITIONS
-- Map: variable name -> { filename, embedded code }
local modules = {
  GMA = {
    file = "gma.lua",
    code = [==[
]==]
  },
  C = {
    file = "constants.lua",
    code = [==[
]==]
  },
  UI = {
    file = "ui.lua",
    code = [==[
]==]
  },
  XML = {
    file = "ui_xml.lua",
    code = [==[
]==]
  },
  S = {
    file = "signals.lua",
    code = [==[
]==]
  },
  O = {
    file = "operators.lua",
    code = [==[
]==]
  },
}

-- WRITE AND LOAD MODULES
local function import_modules()
  local pluginLibPath = GetPath(Enums.PathType.PluginLibrary)

  -- Possible development paths (Windows and macOS)
  local devModulePaths = {
    'C:\\Users\\Juri\\Desktop\\GrandMA3 Plugins\\TimeMAtricks\\modules\\',
    '/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks/modules/'
  }

  -- Find which dev path exists
  local devModulePath = nil
  for _, path in ipairs(devModulePaths) do
    local testFile = io.open(path .. "gma.lua", "r")
    if testFile then
      testFile:close()
      devModulePath = path
      Echo("[MODULES] Using development path: %s", devModulePath)
      break
    end
  end

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
    S = function(result) S = result end,
    O = function(result) O = result end
  }

  for moduleName, moduleData in pairs(modules) do
    local fileName = "TM_" .. moduleData.file
    local pluginLibFile = pluginModulePath .. fileName
    local loaded = false

    -- First, try to load from development directory (if found)
    if devModulePath then
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
          -- Echo("Copied dev module %s to plugin library", moduleData.file)
        else
          ErrEcho("Failed to copy dev module %s to plugin library", moduleData.file)
        end

        -- Load from plugin library (not dev directory)
        local success, result = pcall(dofile, pluginLibFile)
        if success then
          if moduleVars[moduleName] then
            moduleVars[moduleName](result)
          end
          loaded = true
          -- Echo("Loaded module %s", pluginLibFile)
        else
          ErrEcho("Error loading module %s from plugin library: %s", pluginLibFile, result)
        end
      end
    end

    -- Fall back to embedded module code if not loaded from dev path
    if not loaded then
      local file = io.open(pluginLibFile, "w")
      if file then
        file:write(moduleData.code)
        file:close()
        -- Echo("Written embedded module %s to plugin library", moduleName)

        -- Load the module
        local success, result = pcall(dofile, pluginLibFile)
        if success then
          if moduleVars[moduleName] then
            moduleVars[moduleName](result)
          end
        else
          ErrEcho("Error loading module %s: %s", moduleName, result)
        end
      else
        ErrEcho("Error writing module %s to file", moduleName)
      end
    end
  end
end

------------------------
-- MAIN LOOP AND EXIT --
------------------------

local function loop()
  if PluginRunning then
    pluginAlive = true

    -- Get all matricks configuration from globals
    local config = {
      -- Matricks enabled states (1 or 0)
      mx1_enabled = GMA.get_global(C.GVars.mx1) or 0,
      mx2_enabled = GMA.get_global(C.GVars.mx2) or 0,
      mx3_enabled = GMA.get_global(C.GVars.mx3) or 0,
      mx_prefix_enabled = GMA.get_global(C.GVars.prefix) or 0,

      -- Matricks names (e.g., "Test Matricks")
      mx1_name = GMA.get_global(C.GVars.mx1name) or "",
      mx2_name = GMA.get_global(C.GVars.mx2name) or "",
      mx3_name = GMA.get_global(C.GVars.mx3name) or "",
      mx_prefix_name = GMA.get_global(C.GVars.prefixname) or "",

      -- Matricks rates (multipliers)
      mx1_rate = tonumber(GMA.get_global(C.GVars.mx1rate) or 0.25) or 0.25,
      mx2_rate = tonumber(GMA.get_global(C.GVars.mx2rate) or 0.5) or 0.5,
      mx3_rate = tonumber(GMA.get_global(C.GVars.mx3rate) or 1.0) or 1.0,

      -- Master configuration
      master_id = GMA.get_global(C.GVars.mvalue) or "",
      timing_enabled = tonumber(GMA.get_global(C.GVars.timing) or 0) or 0,
      speed_enabled = tonumber(GMA.get_global(C.GVars.speed) or 0) or 0,

      -- Overall rate scaling
      overall_rate = tonumber(GMA.get_global(C.GVars.ovrate) or 1.0) or 1.0,

      -- Fade configuration
      fade_enabled = GMA.get_global(C.GVars.fade),
      fade_amount = tonumber(GMA.get_global(C.GVars.fadeamount) or 0.5) or 0.5,
    }


    -- Only execute if a master is configured and enabled
    if config.master_id ~= "" and (config.timing_enabled == 1 or config.speed_enabled == 1) then
      -- Get normalized timing from master
      local timing = O.get_master_fader_normalized()

      if timing and timing > 0 then
        -- Apply overall rate scaling
        timing = timing / config.overall_rate

        -- Determine fade/delay split
        local fadeAmount = config.fade_enabled == false and 0 or (config.fade_amount or 0.5)

        -- Get prefix to apply (if enabled)
        local prefix = (config.mx_prefix_enabled == 1 and config.mx_prefix_name ~= "") and (config.mx_prefix_name) or ""

        -- Apply matricks triplets if enabled
        if config.mx1_enabled == 1 then
          O.apply_matricks_triplet(config.mx1_name, config.mx1_rate, prefix, fadeAmount, timing)
        end
        if config.mx2_enabled == 1 then
          O.apply_matricks_triplet(config.mx2_name, config.mx2_rate, prefix, fadeAmount, timing)
        end
        if config.mx3_enabled == 1 then
          O.apply_matricks_triplet(config.mx3_name, config.mx3_rate, prefix, fadeAmount, timing)
        end
      else
        Echo("WARNING: Timing not valid: " .. tostring(timing))
      end
    end
  end

  -- Get refresh rate from settings (default 1 second)
  local refreshrate = tonumber(GMA.get_global(C.GVars.refresh) or 0.5) or 0.5
  coroutine.yield(refreshrate)
end

local function kill_plugin()
  UI.delete_icon()
  CloseAllOverlays()
  pluginAlive = false
  PluginRunning = false
  local path = GetPath(Enums.PathType.PluginLibrary)
  local plfolder = path .. "/TimeMAtricks/"

  -- Remove individual module files
  local moduleFiles = { "TM_gma.lua", "TM_constants.lua", "TM_ui.lua", "TM_ui_xml.lua", "TM_signals.lua",
    "TM_operators.lua" }
  for _, file in ipairs(moduleFiles) do
    os.remove(plfolder .. file)
  end

  -- Remove XML files in temp directory
  local tempPath = GetPath("temp") .. "/TimeMAtricks/"
  local xmlFiles = { "TimeMAtricks_Menu.xml", "TimeMAtricks_Settings.xml", "TimeMAtricks_Small.xml" }
  for _, file in ipairs(xmlFiles) do
    os.remove(tempPath .. file)
  end

  -- Remove temp folders
  os.remove(tempPath)

  -- Remove the plugin library folder
  os.remove(plfolder)
end

---------------------
-- MAIN ENTRYPOINT --
---------------------

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
    coroutine.yield(0.1) -- Wait a moment for icon to appear
    SignalTable.open_menu()
    local firstopen = GMA.get_global("TM_firststart") or nil
    if not firstopen then
      GMA.pool_check()
      GMA.msgbox({
        title = "First Launch",
        message = "Press the Settings button at the top to configure the starting MAtricks pool number.",
        commands = { { value = 1, name = "Ok" } },
        icon = "QuestionMarkIcon",
        timeout = 10000,
        backColor = "Window.Plugins",
      })
      GMA.set_global("TM_firststart", true)
    end
    GMA.set_global(C.GVars.firststart, true)
    Timer(loop, 0, 0, kill_plugin)
  else
    SignalTable.open_menu()
  end
end

return main
