---@diagnostic disable: redundant-parameter

UI = {}

function UI.save()
end

function UI.load()
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

function UI.create_menu()
  local ui = C.screenOV:Append('BaseInput')
  ui.SuppressOverlayAutoclose = "Yes"
  ui.AutoClose = "No"
  ui.CloseOnEscape = "Yes"
  local path, file = XML.importxml("ui")
  ui:Import(path, file)
end

function UI.add_element(elementType, properties)
end

function UI.echo(message)
  Echo("UI READY!")
end

return UI
