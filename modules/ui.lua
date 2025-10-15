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
  X = function(el, value) el.X = value end,
  Y = function(el, value) el.Y = value end,

  -- Event handlers
  Clicked = function(el, value) el.Clicked = value end,
  KeyDown = function(el, value) el.KeyDown = value end,
  MouseDownHold = function(el, value) el.MouseDownHold = value end,

  -- Plugin component
  PluginComponent = function(el, value) el.PluginComponent = value end,
}

function UI.save()
end

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

function UI.create_icon(handle)
  local lastCols = tonumber(C.cmdLN.Columns)
  local cols = lastCols + 1
  C.cmdLN.Columns = cols

  TMIcon = C.cmdLN:Append("Button")
  TMIcon.Name = C.CMD_ICON_NAME
  TMIcon.Anchors = { left = cols - 2 }
  TMIcon.W = 49
  TMIcon.H = "100%"
  TMIcon.PluginComponent = handle
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

function UI.add_element(elementType, properties)
end

function UI.fill_element(obj, property_or_table, value)
  local el = C.UI:FindRecursive(obj)
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
  C.UI = C.screenOV:Append('BaseInput')
  C.UI.SuppressOverlayAutoclose = "Yes"
  C.UI.AutoClose = "No"
  C.UI.CloseOnEscape = "Yes"
  local path, file = XML.importxml("ui")
  C.UI:Import(path, file)
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
