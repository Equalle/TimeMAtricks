---@diagnostic disable: redundant-parameter

UI = {}

-----------------
--- PROPERTIES --
-----------------

UI.PROPERTY_MAP = {
  -- Text properties
  Text = function(el, value) el.Text = value end,
  Content = function(el, value) el.Content = value end,
  Tooltip = function(el, value) el.Tooltip = value end,

  -- Color properties
  BackColor = function(el, value) el.BackColor = value end,
  TextColor = function(el, value) el.TextColor = value end,
  IconColor = function(el, value) el.IconColor = value end,

  -- Visual properties
  Icon = function(el, value) el.Icon = value end,
  Font = function(el, value) el.Font = value end,
  Visible = function(el, value) el.Visible = value end,
  Enabled = function(el, value) el.Enabled = value end,

  -- State properties
  State = function(el, value) el.State = value end,

  -- Size/Position properties
  H = function(el, value) el.H = value end,
  W = function(el, value) el.W = value end,

  -- Event handlers
  Clicked = function(el, value) el.Clicked = value end,
  KeyDown = function(el, value) el.KeyDown = value end,
  MouseDownHold = function(el, value) el.MouseDownHold = value end,

  -- Plugin component
  PluginComponent = function(el, value) el.PluginComponent = value end,
}

---------------
-- SAVE/LOAD --
---------------

-- Saves current UI data to variables
function UI.save()
end

-- Loads current UI data with variable data
function UI.load()
  -- Title
  UI.edit_element("TitleButton", {
    Text = C.PLUGIN_NAME,
    Icon = C.icons.matricks,
  })
  -- Version
  UI.edit_element("Version", { Text = "Version: " .. C.PLUGIN_VERSION, })

  -- Plugin On/Off
  if PluginRunning then
    UI.edit_element("PlOn", {
      BackColor = C.colors.button.please,
      TextColor = C.colors.icon.active,
    })
    UI.edit_element("PlOff", {
      BackColor = C.colors.button.default,
      TextColor = C.colors.icon.inactive,
    })
  else
    UI.edit_element("PlOn", {
      BackColor = C.colors.button.default,
      TextColor = C.colors.icon.inactive,
    })
    UI.edit_element("PlOff", {
      BackColor = C.colors.button.please,
      TextColor = C.colors.icon.active,
    })
  end

  -- Matricks Toggles - Load state and enable/disable corresponding fields
  local mx1State = GMA.get_global(C.GVars.mx1) or 1
  GMA.set_global(C.GVars.mx1, mx1State)
  UI.edit_element("Matricks 1", { State = mx1State })
  local mx1EnableState = (mx1State == 1) and "Yes" or "No"
  UI.edit_element("Matricks 1 Name", { Enabled = mx1EnableState })
  UI.edit_element("Matricks 1 Rate", { Enabled = mx1EnableState })

  local mx2State = GMA.get_global(C.GVars.mx2) or 1
  GMA.set_global(C.GVars.mx2, mx2State)
  UI.edit_element("Matricks 2", { State = mx2State })
  local mx2EnableState = (mx2State == 1) and "Yes" or "No"
  UI.edit_element("Matricks 2 Name", { Enabled = mx2EnableState })
  UI.edit_element("Matricks 2 Rate", { Enabled = mx2EnableState })

  local mx3State = GMA.get_global(C.GVars.mx3) or 1
  GMA.set_global(C.GVars.mx3, mx3State)
  UI.edit_element("Matricks 3", { State = mx3State })
  local mx3EnableState = (mx3State == 1) and "Yes" or "No"
  UI.edit_element("Matricks 3 Name", { Enabled = mx3EnableState })
  UI.edit_element("Matricks 3 Rate", { Enabled = mx3EnableState })

  -- Matricks Prefix Toggle
  local prefixState = GMA.get_global(C.GVars.prefix) or 1
  GMA.set_global(C.GVars.prefix, prefixState)
  UI.edit_element("Matricks Prefix", { State = prefixState })
  local prefixEnableState = (prefixState == 1) and "Yes" or "No"
  UI.edit_element("Matricks Prefix Name", { Enabled = prefixEnableState })


  -- Matricks Name fields
  UI.edit_element("Matricks 1 Name", { Content = tostring(GMA.get_global(C.GVars.mx1name) or ""), })
  UI.edit_element("Matricks 2 Name", { Content = tostring(GMA.get_global(C.GVars.mx2name) or ""), })
  UI.edit_element("Matricks 3 Name", { Content = tostring(GMA.get_global(C.GVars.mx3name) or ""), })

  -- Matricks Rate fields
  UI.edit_element("Matricks 1 Rate", { Content = tostring(GMA.get_global(C.GVars.mx1rate) or ""), })
  UI.edit_element("Matricks 2 Rate", { Content = tostring(GMA.get_global(C.GVars.mx2rate) or ""), })
  UI.edit_element("Matricks 3 Rate", { Content = tostring(GMA.get_global(C.GVars.mx3rate) or ""), })

  -- Prefix Name field
  UI.edit_element("Matricks Prefix Name", { Content = tostring(GMA.get_global(C.GVars.prefixname) or ""), })

  -- CmdIcon
  C.CMD_ICON = C.cmdLN:FindRecursive(C.CMD_ICON_NAME)
  C.CMD_ICON.Icon = C.icons.matricks
  -- Master Select
  UI.edit_element("MstTiming", { State = GMA.get_global(C.GVars.timing) or 1 })
  UI.edit_element("MstSpeed", { State = GMA.get_global(C.GVars.speed) or 0 })
  -- Master Value
  UI.edit_element("Master ID", { Content = tostring(GMA.get_global(C.GVars.mvalue) or "") })

  -- Rate
  UI.edit_element("OVRate", { Text = tostring(GMA.get_global(C.GVars.ovrate) or 1) })

  -- Fade Buttons
  O.fade_set_from_global()
end

function UI.save_settings()
end

function UI.load_settings()
  UI.edit_settings_element("TitleButton", {
    Text = C.PLUGIN_NAME .. " Settings",
    Icon = C.icons.matricks,
  })

  UI.edit_settings_element("Matricks Start", { Content = tostring(GMA.get_global(C.GVars.mxstart) or 1) })
  UI.edit_settings_element("Refresh Rate", { Content = tostring(GMA.get_global(C.GVars.refresh) or 0.5) })
end

function UI.save_small()
end

function UI.load_small()
  if PluginRunning then
    UI.edit_small_element("PlOn", {
      BackColor = C.colors.button.please,
      TextColor = C.colors.icon.active,
    })
    UI.edit_small_element("PlOff", {
      BackColor = C.colors.button.default,
      TextColor = C.colors.icon.inactive,
    })
  else
    UI.edit_small_element("PlOn", {
      BackColor = C.colors.button.default,
      TextColor = C.colors.icon.inactive,
    })
    UI.edit_small_element("PlOff", {
      BackColor = C.colors.button.please,
      TextColor = C.colors.icon.active,
    })
  end
end

---------------
--- HELPERS ---
---------------

-- Find an element by name from the collected UI_ELEMENTS table
function UI.find_element(name)
  if not C.UI_ELEMENTS then
    ErrEcho("UI.find_element: C.UI_ELEMENTS not initialized")
    return nil
  end

  for _, elem in ipairs(C.UI_ELEMENTS) do
    if elem.name == name then
      return elem.handle
    end
  end

  ErrEcho("UI.find_element: Element '%s' not found", name)
  return nil
end

-- Recursively assign PluginComponent to all interactive elements
-- Returns: count of elements, table of element info
function UI.assign_plugin_components(menu)
  if not menu then
    ErrEcho("UI.assign_plugin_components: parentElement is nil")
    return 0, {}
  end

  local count = 0
  local visited = {}  -- Prevent infinite loops
  local elements = {} -- Table to store element information
  local menuName = menu == C.UI_MENU and "MAIN MENU" or "SETTINGS MENU"

  -- Helper function to recursively process elements
  local function process_element(el)
    if not el then return end

    -- Prevent revisiting the same element
    if visited[el] then return end
    visited[el] = true

    -- Check if this is an interactive element that needs PluginComponent
    local class = el:GetClass()
    if class then
      for _, interactiveClass in ipairs(C.INTERACTIVE_CLASSES) do
        if class == interactiveClass then
          -- Exclude buttons with TextColor="CheckBox.ReadOnlyText" (read-only display buttons)
          -- This applies to all menus, not just main menu
          local textColor = el.TextColor
          if not (class == "Button" and textColor == "CheckBox.ReadOnlyText") then
            el.PluginComponent = MyHandle
            count = count + 1
            local name = el.Name or "unnamed"

            -- Store element information
            table.insert(elements, {
              class = class,
              name = name,
              handle = el
            })
          end
          break
        end
      end
    end

    -- Iterate through children using 1-based indexing
    local i = 1
    while true do
      local child = el[i]
      if not child then break end
      process_element(child)
      i = i + 1
      if i > 1000 then break end -- Safety limit
    end

    -- Also try 0-based indexing
    i = 0
    while true do
      local child = el[i]
      if not child then break end
      process_element(child)
      i = i + 1
      if i > 1000 then break end -- Safety limit
    end

    -- Try using Children() with Ptr()
    local success, children = pcall(function() return el:Children() end)
    if success and children then
      local i = 1
      while true do
        local success2, child = pcall(function() return children:Ptr(i) end)
        if not success2 or not child then break end
        process_element(child)
        i = i + 1
        if i > 1000 then break end -- Safety limit
      end
    end
  end

  process_element(menu)

  return count, elements
end

-- Returns cmdline or screenoverlay object
-- Input "cmdLN" or "screenOV"
local function get_dir(dir)
  return (dir == "cmdLN" and GetDisplayByIndex(1).CmdLineSection) or
      (dir == "screenOV" and GetDisplayByIndex(1).ScreenOverlay)
end

-- dirname = cmdLN or screenOV
-- Returns if the entered object exists in the specified Menu
function UI.is_valid_item(obj, dirname)
  local dir = get_dir(dirname)
  if not dir then
    ErrEcho("dir is not cmdLN or screenOV")
    return false
  end
  local found = dir:FindRecursive(obj)
  if not found then
    -- ErrEcho("%s not found in %s", obj, dirname)
  end
  return found ~= nil
end

-- Edits a UI element property or multiple properties
-- obj = string name of the element to edit
-- property_or_table = string property name or table of properties
-- value = value to set (if property_or_table is string)
function UI.edit_element(obj, property_or_table, value)
  local el = C.UI_MENU:FindRecursive(obj)
  if not el then
    ErrEcho("Element %s not found in UI", obj)
    return false
  end

  -- Check if property_or_table is actually a table of properties
  if type(property_or_table) == "table" and value == nil then
    -- Table mode: property_or_table = { Text = "Hello", Icon = "star", ... }
    for prop, val in pairs(property_or_table) do
      local func = UI.PROPERTY_MAP[prop]
      if func then
        func(el, val)
      else
        ErrEcho("Property %s not found in PROPERTY_MAP", prop)
      end
    end
  else
    -- Single property mode: property_or_table = "Text", value = "Hello"
    local func = UI.PROPERTY_MAP[property_or_table]
    if func then
      func(el, value)
    else
      ErrEcho("Property %s not found in PROPERTY_MAP", property_or_table)
    end
  end
  return true
end

function UI.edit_settings_element(obj, property_or_table, value)
  local el = C.UI_SETTINGS:FindRecursive(obj)
  if not el then
    ErrEcho("Element %s not found in UI_SETTINGS", obj)
    return false
  end

  -- Check if property_or_table is actually a table of properties
  if type(property_or_table) == "table" and value == nil then
    -- Table mode: property_or_table = { Text = "Hello", Icon = "star", ... }
    for prop, val in pairs(property_or_table) do
      local func = UI.PROPERTY_MAP[prop]
      if func then
        func(el, val)
      else
        ErrEcho("Property %s not found in PROPERTY_MAP", prop)
      end
    end
  else
    -- Single property mode: property_or_table = "Text", value = "Hello"
    local func = UI.PROPERTY_MAP[property_or_table]
    if func then
      func(el, value)
    else
      ErrEcho("Property %s not found in PROPERTY_MAP", property_or_table)
    end
  end
  return true
end

function UI.edit_small_element(obj, property_or_table, value)
  local el = C.UI_SMALL:FindRecursive(obj)
  if not el then
    ErrEcho("Element %s not found in UI_SMALL", obj)
    return false
  end

  -- Check if property_or_table is actually a table of properties
  if type(property_or_table) == "table" and value == nil then
    -- Table mode: property_or_table = { Text = "Hello", Icon = "star", ... }
    for prop, val in pairs(property_or_table) do
      local func = UI.PROPERTY_MAP[prop]
      if func then
        func(el, val)
      else
        ErrEcho("Property %s not found in PROPERTY_MAP", prop)
      end
    end
  else
    -- Single property mode: property_or_table = "Text", value = "Hello"
    local func = UI.PROPERTY_MAP[property_or_table]
    if func then
      func(el, value)
    else
      ErrEcho("Property %s not found in PROPERTY_MAP", property_or_table)
    end
  end
  return true
end

---------------
-- CREATE UI --
---------------

-- Creates the command line icon button
function UI.create_icon()
  local lastCols = tonumber(C.cmdLN.Columns)
  local cols = lastCols + 1
  C.cmdLN.Columns = cols

  C.CMD_ICON = C.cmdLN:Append("Button")
  C.CMD_ICON.Name = C.CMD_ICON_NAME
  C.CMD_ICON.Anchors = { left = cols - 2 }
  C.CMD_ICON.W = 49
  C.CMD_ICON.H = "100%"
  C.CMD_ICON.PluginComponent = MyHandle
  C.CMD_ICON.Clicked = 'open_menu'
  C.CMD_ICON.MouseDownHold = 'nothing'
  C.CMD_ICON.Tooltip = C.PLUGIN_NAME .. " Plugin"
  -- Swipe gesture detection
  C.CMD_ICON.MouseDown = ':icon_mouse_down'
  C.CMD_ICON.MouseUp = ':icon_mouse_up'
  C.CMD_ICON.MouseLeave = ':icon_mouse_leave'
  C.CMD_ICON.HotKey = 'Shift+M'

  Tri = C.cmdLN:FindRecursive("RightTriangle")
  if Tri then
    Tri.Anchors = { left = cols - 1, right = -1, top = -1, bottom = -1 }
    C.cmdLN[2][cols].SizePolicy = "Fixed"
    C.cmdLN[2][cols].Size = 50
  end
end

-- Creates the main plugin menu
function UI.create_menu()
  C.UI_MENU = C.screenOV:Append('BaseInput')
  C.UI_MENU.SuppressOverlayAutoclose = "Yes"
  C.UI_MENU.AutoClose = "No"
  C.UI_MENU.CloseOnEscape = "Yes"
  local path, file = XML.importxml("ui")
  C.UI_MENU:Import(path, file)

  C.UI_MENU:HookDelete(SignalTable.close_menu, C.UI_MENU)

  -- Automatically assign PluginComponent to all interactive elements
  local count, elements = UI.assign_plugin_components(C.UI_MENU)

  -- Store the elements table for later use
  C.UI_ELEMENTS = elements

  -- Initialize the signals module element references
  if S and S.init_elements then
    S.init_elements()
  end

  C.UI_MENU_WARNING = C.UI_MENU:FindRecursive("TitleWarningButton")

  coroutine.yield(0.05) -- Wait a moment for UI to build

  FindBestFocus(C.UI_MENU)
end

function UI.create_settings()
  C.UI_SETTINGS = C.screenOV:Append('BaseInput')
  C.UI_SETTINGS.SuppressOverlayAutoclose = "Yes"
  C.UI_SETTINGS.AutoClose = "No"
  C.UI_SETTINGS.CloseOnEscape = "Yes"
  local path, file = XML.importxml("settings")
  C.UI_SETTINGS:Import(path, file)

  C.UI_SETTINGS:HookDelete(SignalTable.close_menu, C.UI_SETTINGS)

  -- Automatically assign PluginComponent to all interactive elements
  local count, elements = UI.assign_plugin_components(C.UI_SETTINGS)

  -- Store the elements table for later use
  C.UI_ELEMENTS = elements

  -- Initialize the signals module element references for settings menu
  if S and S.init_settings_elements then
    S.init_settings_elements()
  end

  C.UI_SETTINGS_WARNING = C.UI_SETTINGS:FindRecursive("TitleWarningButton")

  coroutine.yield(0.05) -- Wait a moment for UI to build

  FindBestFocus(C.UI_SETTINGS)
end

function UI.create_small()
  local menu = C.screenOV:FindRecursive(C.UI_SMALL_NAME)
  if not menu then
    C.UI_SMALL = C.screenOV:Append('BaseInput')
    C.UI_SMALL.SuppressOverlayAutoclose = "Yes"
    C.UI_SMALL.AutoClose = "No"
    C.UI_SMALL.CloseOnEscape = "Yes"
    C.UI_SMALL.AlignmentH = "Right"
    C.UI_SMALL.AlignmentV = "Bottom"
    C.UI_SMALL.W = 300
    C.UI_SMALL.H = 150

    local path, file = XML.importxml("small")
    C.UI_SMALL:Import(path, file)

    C.UI_SMALL:HookDelete(SignalTable.close_small, C.UI_SMALL)
    C.UI_SMALL.PluginButtons.PluginComponent = MyHandle
    C.UI_SMALL.PluginButtons.MouseLeave = 'close_small'

    -- Automatically assign PluginComponent to all interactive elements
    local count, elements = UI.assign_plugin_components(C.UI_SMALL)

    -- Debug: Check PluginComponent of buttons
    local plOn = C.UI_SMALL:FindRecursive("PlOn")
    local plOff = C.UI_SMALL:FindRecursive("PlOff")
    UI.load_small()
  end
end

------------
-- Delete --
------------

function UI.delete_icon()
  if UI.is_valid_item(C.CMD_ICON_NAME, "cmdLN") then
    local iconpos = C.CMD_ICON.Anchors.left or 0
    -- Delete Icon
    C.cmdLN:Remove(C.CMD_ICON:Get("No"))
    C.CMD_ICON = nil

    -- Adjust cmdLN columns
    local lastCols = tonumber(C.cmdLN.Columns)
    C.cmdLN.Columns = lastCols - 1

    for i = 1, C.cmdLN:Count() do
      local el = C.cmdLN:Ptr(i)
      if el and el.Anchors and el.Anchors.left then
        local itempos = el.Anchors.left
        if itempos > iconpos then
          el.Anchors.left = itempos - 2
        end
      end
    end

    Tri = GetDisplayByIndex(1):FindRecursive("RightTriangle")
    if Tri then
      Tri.Anchors = { left = lastCols - 2, right = -1, top = -1, bottom = -1 }
    end
  end
end

return UI
