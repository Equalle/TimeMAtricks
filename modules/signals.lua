---@diagnostic disable redundant-parameter

S = {}

-- Initialize elements table - will be populated after UI is created
local elements = {}

-- Populate elements table with UI element handles
function S.init_elements()
  elements = {
    -- Buttons
    PlOn = UI.find_element("PlOn"),
    PlOff = UI.find_element("PlOff"),
    MstTiming = UI.find_element("MstTiming"),
    MstSpeed = UI.find_element("MstSpeed"),
    FLess = UI.find_element("FadeLess"),
    FMore = UI.find_element("FadeMore"),
    RateHalf = UI.find_element("1/2"),
    RateDouble = UI.find_element("2"),
    RateOne = UI.find_element("Reset"),
    Apply = UI.find_element("Apply"),
    Close = UI.find_element("Close"),

    -- CheckBoxes
    MxPreToggle = UI.find_element("Matricks Prefix"),
    Mx1Toggle = UI.find_element("Matricks 1"),
    Mx2Toggle = UI.find_element("Matricks 2"),
    Mx3Toggle = UI.find_element("Matricks 3"),

    -- LineEdits
    MstID = UI.find_element("Master ID"),
    MxPreName = UI.find_element("Matricks Prefix Name"),
    Mx1Name = UI.find_element("Matricks 1 Name"),
    Mx2Name = UI.find_element("Matricks 2 Name"),
    Mx3Name = UI.find_element("Matricks 3 Name"),
    Mx1Rate = UI.find_element("Matricks 1 Rate"),
    Mx2Rate = UI.find_element("Matricks 2 Rate"),
    Mx3Rate = UI.find_element("Matricks 3 Rate"),
  }
end

----------
-- MENU --
----------

SignalTable.open_menu = function()
  if not UI.is_valid_item(C.UI_MENU_NAME, "screenOV") then
    UI.create_menu()
    FindBestFocus(GetTopOverlay(1))
  else
    UI.edit_element(C.UI_MENU_NAME, "Visible", "YES")
  end
  UI.load()
end

SignalTable.close_menu = function(caller)
  UI.save()
  if C.UI_MENU then
    if caller and caller.Name == "Close" then
      GMA.press_key("Escape")
    end
  elseif caller and caller == C.UI_SETTINGS then
    C.UI_MENU.Visible = "Yes"
  end
end

-------------
-- BUTTONS --
-------------

SignalTable.plugin_off = function()
  PluginRunning = false

  -- Set PluginOn colors
  if elements.PlOn then
    elements.PlOn.BackColor = C.colors.button.default
    elements.PlOn.TextColor = C.colors.icon.inactive
  end

  -- Set PluginOff colors
  if elements.PlOff then
    elements.PlOff.BackColor = C.colors.button.clear
    elements.PlOff.TextColor = C.colors.icon.active
  end

  -- set Title icon color
  local tb = C.UI_MENU:FindRecursive("TitleButton")
  if tb then
    tb.IconColor = C.colors.icon.inactive
  end

  -- Set command line icon color
  C.CMD_ICON.IconColor = C.colors.icon.inactive
end

SignalTable.plugin_on = function()
  PluginRunning = true

  -- Set PluginOn colors
  if elements.PlOn then
    elements.PlOn.BackColor = C.colors.button.please
    elements.PlOn.TextColor = C.colors.icon.active
  end

  -- Set PluginOff colors
  if elements.PlOff then
    elements.PlOff.BackColor = C.colors.button.default
    elements.PlOff.TextColor = C.colors.icon.inactive
  end

  -- Set Title icon color
  local tb = C.UI_MENU:FindRecursive("TitleButton")
  if tb then
    tb.IconColor = C.colors.icon.active
  end

  -- Set command line icon color
  C.CMD_ICON.IconColor = C.colors.icon.active
end

SignalTable.set_master = function(caller)
  if caller and caller == elements.MstTiming then
    GMA.set_globalV(C.GVars.timing, 1)
    GMA.set_globalV(C.GVars.speed, 0)

    if elements.MstTiming then
      elements.MstTiming.TextColor = C.colors.icon.active
    end
    if elements.MstSpeed then
      elements.MstSpeed.TextColor = C.colors.icon.inactive
    end
  elseif caller and caller == elements.MstSpeed then
    GMA.set_globalV(C.GVars.timing, 0)
    GMA.set_globalV(C.GVars.speed, 1)

    if elements.MstTiming then
      elements.MstTiming.TextColor = C.colors.icon.inactive
    end
    if elements.MstSpeed then
      elements.MstSpeed.TextColor = C.colors.icon.active
    end
  end
end

SignalTable.matricks_toggle = function(caller)
  -- Code to toggle matricks
  Echo(">PH<   toggle_matricks")
end

SignalTable.prefix_toggle = function(caller)
  -- Code to toggle prefix
  Echo(">PH<   toggle_prefix")
  if elements.MxPreName then
    if caller.State == 1 then
      caller.State = 0
      elements.MxPreName.Enabled = "No"
    elseif caller.State == 0 then
      caller.State = 1
      elements.MxPreName.Enabled = "Yes"
    end
  end
end

SignalTable.fade_change = function(caller)
  -- Code to change fade
  Echo(">PH<   fade_change")
end

----------
-- HOLD --
----------

SignalTable.fade_toggle = function(caller)
  -- Code to toggle fade
  Echo(">PH<   fade_toggle")
end

SignalTable.rate_change = function(caller)
  -- Code to change rate
  Echo(">PH<   rate_change")
end

SignalTable.apply_changes = function(caller)
  -- Code to apply changes
  Echo(">PH<   apply_changes")
end

--------------
-- LINEEDIT --
--------------

SignalTable.text_master = function(caller)
  if caller then
    Echo("%s: %s", caller.Name, caller.Content)
    before = caller.Content
    after = O.master_limit(caller, before)
    if after ~= before then
      caller.Content = after
      if caller.HasFocus then
        GMA.press_key("End")
        if caller == elements.MstID then
          if GMA.get_globalV(C.GVars.timing) == 1 then
            SignalTable.show_warning(caller, "Timing Master 1-50")
          elseif GMA.get_globalV(C.GVars.speed) == 1 then
            SignalTable.show_warning(caller, "Speed Master 1-16")
          else
            SignalTable.show_warning(caller, "Maximum 2 Digits")
          end
        end
      end
    end
  end
end

SignalTable.text_rate = function(caller)
  if caller then
    Echo("%s: %s", caller.Name, caller.Content)
  end
end

SignalTable.key_down = function(caller, dummy, keycode)
  if caller.HasFocus and keycode == Enums.KeyboardCodes.Enter then
    Echo("Enter -> %s: %s", caller.Name, caller.Content)
    FindNextFocus(caller)
  end
end

-- FOCUS

SignalTable.LineEditSelectAll = function(caller)
  if caller then
    caller:SelectAll()
    Echo("%s selected", caller.Name)
  end
end

SignalTable.LineEditDeselect = function(caller)
  if caller then
    caller:Deselect()
    ErrEcho("%s deselected", caller.Name)
  end
end

-------------
-- WARNING --
-------------

SignalTable.show_warning = function(caller, status)
  if caller and status and status == "Name is too long (maximum 2 characters)" then
    if GMA.get_globalV(C.GVars.timing) == 1 then
      status = "Timing Master 1-50"
    elseif GMA.get_globalV(C.GVars.speed) == 1 then
      status = "Speed Master 1-16"
    else
      status = "Maximum 2 Digits"
    end
  end
  C.UI_MENU_WARNING.ShowAnimation(status)

  if PluginError then
    PluginError = nil
    coroutine.yield(0.05)
    FindNextFocus(true)
  end
end

SignalTable.show_apply = function(caller)
  C.UI_MENU_APPLY.ShowAnimation("")
end

-- Debug
function S.echo(message)
  Echo("SIGNALS READY!")
end

return S
