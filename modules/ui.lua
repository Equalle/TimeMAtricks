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
  UI.edit_element("TitleButton", {
    Text = C.PLUGIN_NAME,
    Icon = C.icons.matricks,
  })
  UI.edit_element("Version", {
    Text = "Version: " .. C.PLUGIN_VERSION,
  })
  -- Initialize fade enable state to true if not set
  local fadeState = GMA.get_global(C.GVars.fade)
  if fadeState == nil then
    GMA.set_global(C.GVars.fade, true)
  end
  C.CMD_ICON.Icon = C.icons.matricks
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

  -- Echo the collected elements table
  if count > 0 then
    -- Echo("=== Assigned PluginComponent to %d elements ===", count)
    for i, elem in ipairs(elements) do
      -- Echo("  [%d] %s: %s", i, elem.class, elem.name)
    end
  end

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
  C.CMD_ICON.Tooltip = C.PLUGIN_NAME .. " Plugin"

  Tri = C.cmdLN:FindRecursive("RightTriangle")
  if Tri then
    Tri.Anchors = { left = cols - 1 }
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

  -- Load saved fade state (position and enable state) after UI is built
  if O and O.fade_set_from_global then
    O.fade_set_from_global()
  end

  FindBestFocus(C.UI_MENU)
end

-- Debug
function UI.echo(message)
  Echo("UI READY!")
end

return UI
