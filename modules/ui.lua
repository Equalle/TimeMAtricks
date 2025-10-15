---@diagnostic disable: redundant-parameter

UI = {}

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

-- Classes that should have PluginComponent assigned
UI.INTERACTIVE_CLASSES = {
  "Button",
  "LineEdit",
  "CheckBox",
  -- Add more as needed: "Slider", "ComboBox", etc.
}

-- Recursively assign PluginComponent to all interactive elements
function UI.assign_plugin_components(menu)
  if not menu then
    ErrEcho("UI.assign_plugin_components: parentElement is nil")
    return 0
  end

  local count = 0
  local visited = {} -- Prevent infinite loops

  -- Helper function to recursively process elements
  local function process_element(el)
    if not el then return end

    -- Prevent revisiting the same element
    if visited[el] then return end
    visited[el] = true

    -- Check if this is an interactive element that needs PluginComponent
    local class = el:GetClass()
    if class then
      for _, interactiveClass in ipairs(UI.INTERACTIVE_CLASSES) do
        if class == interactiveClass then
          el.PluginComponent = MyHandle
          count = count + 1
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
  return count
end -- Saves current UI data to variables

function UI.save()
end

-- Loads current UI data with variable data
function UI.load()
  UI.fill_element("TitleButton", {
    Text = C.PLUGIN_NAME,
    Icon = C.icons.matricks,
  })
  UI.fill_element("Version", {
    Text = "Version: " .. C.PLUGIN_VERSION,
  })
end

-- Returns cmdline or screenoverlay object
-- Input "cmdLN" or "screenOV"
local function get_dir(dir)
  return (dir == "cmdLN" and GetDisplayByIndex(1).CmdLineSection) or
      (dir == "screenOV" and GetDisplayByIndex(1).ScreenOverlay)
end

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

function UI.create_icon()
  local lastCols = tonumber(C.cmdLN.Columns)
  local cols = lastCols + 1
  C.cmdLN.Columns = cols

  TMIcon = C.cmdLN:Append("Button")
  TMIcon.Name = C.CMD_ICON_NAME
  TMIcon.Anchors = { left = cols - 2 }
  TMIcon.W = 49
  TMIcon.H = "100%"
  TMIcon.PluginComponent = MyHandle
  TMIcon.Clicked = 'open_menu'
  TMIcon.Icon = C.icons.star
  TMIcon.IconColor = C.colors.icon.inactive
  TMIcon.Tooltip = C.PLUGIN_NAME .. " Plugin"

  Tri = C.cmdLN:FindRecursive("RightTriangle")
  if Tri then
    Tri.Anchors = { left = cols - 1 }
    C.cmdLN[2][cols].SizePolicy = "Fixed"
    C.cmdLN[2][cols].Size = 50
  end
end

function UI.add_element(object, menu, options)
  local el = menu:FindRecursive(object)
  if not el then
    ErrPrintf("Element not found: %s", tostring(object))
    return false
  end

  -- Always set PluginComponent
  if UI.PROPERTY_MAP.PluginComponent then
    UI.PROPERTY_MAP.PluginComponent(el, MyHandle)
  end

  -- Apply all properties from options using the property map
  -- Options keys should match PROPERTY_MAP keys exactly (Clicked, State, Content, Text, etc.)
  for prop, value in pairs(options) do
    local propFunc = UI.PROPERTY_MAP[prop]
    if propFunc then
      propFunc(el, value)
    else
      ErrPrintf("Property %s not found in PROPERTY_MAP", prop)
    end
  end

  -- Set default enabled state if not specified
  if options.Enabled == nil then
    if UI.PROPERTY_MAP.Enabled then
      UI.PROPERTY_MAP.Enabled(el, "Yes")
    end
  end

  return true
end

function UI.fill_element(obj, property_or_table, value)
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

function UI.create_menu()
  C.UI_MENU = C.screenOV:Append('BaseInput')
  C.UI_MENU.SuppressOverlayAutoclose = "Yes"
  C.UI_MENU.AutoClose = "No"
  C.UI_MENU.CloseOnEscape = "Yes"
  local path, file = XML.importxml("ui")
  C.UI_MENU:Import(path, file)

  -- Automatically assign PluginComponent to all interactive elements
  UI.assign_plugin_components(C.UI_MENU)
end

function UI.open_menu()
  if not UI.is_valid_item(C.UI_MENU_NAME, "screenOV") then
    UI.create_menu()
    FindBestFocus(GetTopOverlay(1))
  else
    UI.fill_element(C.UI_MENU_NAME, "Visible", "YES")
  end
  UI.load()
end

function UI.echo(message)
  Echo("UI READY!")
end

return UI
