---@diagnostic disable redundant-parameter

S = {}

-- Initialize elements table - will be populated after UI is created
local elements = {}
local settings_elements = {}

-- Populate elements table with UI element handles for main menu
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
    -- Apply = UI.find_element("Apply"),
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

  --Fade Width
  elements.FadeWidth = C.UI_MENU:FindRecursive("Fade Width")
end

-- Populate settings_elements table with UI element handles for settings menu
function S.init_settings_elements()
  settings_elements = {

    -- LineEdits
    StartIndex = UI.find_element("Matricks Start"),
    RefreshRate = UI.find_element("Refresh Rate"),
  }

  -- Debug: Print settings elements initialization
  Echo("DEBUG: Settings Elements Initialized")
  Echo("  StartIndex: " .. tostring(settings_elements.StartIndex))
  Echo("  RefreshRate: " .. tostring(settings_elements.RefreshRate))
end

-- Get the correct element table and overlay based on which menu is active
function S.get_elements()
  if C.UI_SETTINGS and C.UI_SETTINGS.Visible == "Yes" then
    return settings_elements, C.UI_SETTINGS
  else
    return elements, C.UI_MENU
  end
end

-- Get a specific element from the active menu, searching in the correct overlay
function S.get_element(name)
  local elem_table, overlay = S.get_elements()
  if elem_table and elem_table[name] then
    return elem_table[name]
  end
  -- Fallback: search in the overlay directly
  if overlay then
    return UI.find_element(name, overlay)
  end
  return nil
end

-- Find an element in the settings menu specifically
function S.get_settings_element(name)
  if settings_elements and settings_elements[name] then
    return settings_elements[name]
  end
  if C.UI_SETTINGS then
    return UI.find_element(name, C.UI_SETTINGS)
  end
  return nil
end

-- Find an element in the main menu specifically
function S.get_menu_element(name)
  if elements and elements[name] then
    return elements[name]
  end
  if C.UI_MENU then
    return UI.find_element(name, C.UI_MENU)
  end
  return nil
end

----------
-- MENU --
----------

SignalTable.open_menu = function()
  if not UI.is_valid_item(C.UI_MENU_NAME, "screenOV") then
    UI.create_menu()
    FindBestFocus(GetTopOverlay(1))
  else
    -- C.UI_MENU.Visible = "Yes"
    C.UI_MENU.Enabled = "Yes"
  end
  UI.load()
end

SignalTable.open_settings = function()
  if not UI.is_valid_item(C.UI_SETTINGS_NAME, "screenOV") then
    UI.create_settings()
    FindBestFocus(GetTopOverlay(1))
    -- C.UI_MENU.Visible = "No"
    C.UI_MENU.Enabled = "No"
  end
  UI.load_settings()
end

SignalTable.close_menu = function(caller)
  UI.save()
  if caller then
    if caller.Name == "Close" then
      GMA.press_key("Escape")
    end
    if caller:Parent():Parent() == C.UI_SETTINGS then
      GMA.press_key("Escape")
    end
  end
  -- C.UI_MENU.Visible = "Yes"
  C.UI_MENU.Enabled = "Yes"
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
    O.set_master_mode(1)
    UI.edit_element("MstTiming", { State = 1 })
    UI.edit_element("MstSpeed", { State = 0 })
  elseif caller and caller == elements.MstSpeed then
    O.set_master_mode(0)
    UI.edit_element("MstTiming", { State = 0 })
    UI.edit_element("MstSpeed", { State = 1 })
  end
end

SignalTable.matricks_toggle = function(caller)
  if not caller then return end

  -- Toggle the state first
  caller.State = (caller.State == 1) and 0 or 1

  -- Then determine enable state based on NEW state
  local enableState = (caller.State == 1) and "Yes" or "No"

  -- Determine which matricks was toggled and update corresponding fields
  if caller == elements.Mx1Toggle then
    if elements.Mx1Name then
      elements.Mx1Name.Enabled = enableState
    end
    if elements.Mx1Rate then
      elements.Mx1Rate.Enabled = enableState
    end
    GMA.set_global(C.GVars.mx1, caller.State)
    if caller.State == 1 then
      FindBestFocus(elements.Mx1Name)
    end
  elseif caller == elements.Mx2Toggle then
    if elements.Mx2Name then
      elements.Mx2Name.Enabled = enableState
    end
    if elements.Mx2Rate then
      elements.Mx2Rate.Enabled = enableState
    end
    GMA.set_global(C.GVars.mx2, caller.State)
    if caller.State == 1 then
      FindBestFocus(elements.Mx2Name)
    end
  elseif caller == elements.Mx3Toggle then
    if elements.Mx3Name then
      elements.Mx3Name.Enabled = enableState
    end
    if elements.Mx3Rate then
      elements.Mx3Rate.Enabled = enableState
    end
    GMA.set_global(C.GVars.mx3, caller.State)
    if caller.State == 1 then
      FindBestFocus(elements.Mx3Name)
    end
  end
end

SignalTable.prefix_toggle = function(caller)
  if elements.MxPreName then
    if caller.State == 1 then
      caller.State = 0
      GMA.set_global(C.GVars.prefix, 0)
      elements.MxPreName.Enabled = "No"
    elseif caller.State == 0 then
      caller.State = 1
      GMA.set_global(C.GVars.prefix, 1)
      elements.MxPreName.Enabled = "Yes"
    end
  end
end

SignalTable.fade_change = function(caller)
  local direction
  if caller == elements.FLess then
    direction = -1
  elseif caller == elements.FMore then
    direction = 1
  end
  O.fade_adjust(direction)
end

SignalTable.rate_change = function(caller)
  if caller == elements.RateHalf then
    rate = O.adjust_rate(0.5)
  elseif caller == elements.RateDouble then
    rate = O.adjust_rate(2)
  elseif caller == elements.RateOne then
    rate = O.adjust_rate(1)
  end
  UI.edit_element("OVRate", { Text = tostring(rate) })
  GMA.set_global(C.GVars.ovrate, rate)
end

SignalTable.apply_changes = function(caller)
  -- Code to apply changes
  Echo(">PH<   apply_changes")
end

----------
-- HOLD --
----------

SignalTable.fade_toggle = function()
  -- Check current fade enabled state
  local fadeEnabled = GMA.get_global(C.GVars.fade)

  if fadeEnabled == false then
    -- Currently disabled - re-enable it
    GMA.set_global(C.GVars.fade, true)
    -- Re-enable buttons and restore their normal state
    O.fade_adjust(0) -- This will re-enable without moving slider, set correct texts
  else
    -- Currently enabled - disable it
    GMA.set_global(C.GVars.fade, false)
    -- Disable buttons and show disabled state
    elements.FLess.Enabled = "No"
    elements.FLess.Text = "DISABLED"
    elements.FMore.Text = "(Press to enable)"
    -- Reset slider to center
    local center = (C.UI_MENU:Get("W") - 50) / 2
    elements.FadeWidth.Size = center
  end
end


--------------
-- LINEEDIT --
--------------

SignalTable.text_master = function(caller)
  if caller then
    -- Echo("%s: %s", caller.Name, caller.Content)
    before = caller.Content
    after = O.master_limit(caller, before)
    if after ~= before then
      caller.Content = after
      if caller.HasFocus then
        GMA.press_key("End")
        -- Only show warning if content was modified AND it's not empty
        -- This indicates a limit was applied (e.g., 51 -> 50), not just deletion
        if caller == elements.MstID and after ~= "" and before ~= "" then
          if GMA.get_global(C.GVars.timing) == 1 then
            SignalTable.show_warning(caller, "Timing Master 1-50")
            FindBestFocus(caller)
            caller:SelectAll()
          elseif GMA.get_global(C.GVars.speed) == 1 then
            SignalTable.show_warning(caller, "Speed Master 1-16")
            FindBestFocus(caller)
            caller:SelectAll()
          else
            SignalTable.show_warning(caller, "Maximum 2 Digits")
          end
        end
      end
    end
  end
end

SignalTable.text_rate = function(caller)
  if caller and caller == elements.Mx1Rate then
    local before = caller.Content
    local after = O.sanitize_rate(caller.Content, caller)
    if after ~= before then
      elements.Mx1Rate.Content = after
      GMA.press_key("End")
      caller.SelectAll()
    end
    GMA.set_global(C.GVars.mx1rate, after)
  elseif caller and caller == elements.Mx2Rate then
    local before = caller.Content
    local after = O.sanitize_rate(caller.Content, caller)
    if after ~= before then
      elements.Mx2Rate.Content = after
      GMA.press_key("End")
      caller.SelectAll()
    end
    GMA.set_global(C.GVars.mx2rate, after)
  elseif caller and caller == elements.Mx3Rate then
    local before = caller.Content
    local after = O.sanitize_rate(caller.Content, caller)
    if after ~= before then
      elements.Mx3Rate.Content = after
      GMA.press_key("End")
      caller.SelectAll()
    end
    GMA.set_global(C.GVars.mx3rate, after)
  elseif caller and caller == settings_elements.RefreshRate then
    local before = caller.Content
    local after = O.sanitize_refresh(caller.Content, caller)
    if after ~= before then
      settings_elements.RefreshRate.Content = after
      GMA.press_key("End")
      caller.SelectAll()
    end
    GMA.set_global(C.GVars.refresh, after)
  end
end

SignalTable.key_down = function(caller, dummy, keycode)
  if caller.HasFocus and keycode == Enums.KeyboardCodes.Enter then
    -- Echo("Enter -> %s: %s", caller.Name, caller.Content)
    if caller == elements.MstID then
      if caller.Content == "" then
        SignalTable.show_warning(caller, "Please enter a Master ID")
        GMA.press_key("End")
        return
      else
        GMA.set_global(C.GVars.mvalue, tonumber(caller.Content))
      end
    end
    FindNextFocus(caller)
  end
end

-- FOCUS

SignalTable.LineEditSelectAll = function(caller)
  if caller then
    caller:SelectAll()
  end
end

SignalTable.LineEditDeselect = function(caller)
  if caller then
    caller:Deselect()
    if caller == elements.MstID then
      if caller.Content ~= "" then
        GMA.set_global(C.GVars.mvalue, tonumber(caller.Content))
      end
    elseif caller == elements.MxPreName then
      O.save_matricks_name(caller, caller.Content)
    elseif caller == elements.Mx1Name then
      O.save_matricks_name(caller, caller.Content)
    elseif caller == elements.Mx2Name then
      O.save_matricks_name(caller, caller.Content)
    elseif caller == elements.Mx3Name then
      O.save_matricks_name(caller, caller.Content)
    elseif caller == elements.Mx1Rate then
      if caller.Content ~= "" then
        GMA.set_global(C.GVars.mx1rate, caller.Content)
      end
    elseif caller == elements.Mx2Rate then
      if caller.Content ~= "" then
        GMA.set_global(C.GVars.mx2rate, caller.Content)
      end
    elseif caller == elements.Mx3Rate then
      if caller.Content ~= "" then
        GMA.set_global(C.GVars.mx3rate, caller.Content)
      end
    elseif caller == settings_elements.StartIndex then
      if caller.Content ~= "" then
        local num = tonumber(caller.Content)
        if num and num == 0 then
          caller.Content = "1"
          SignalTable.show_warning(caller, "Cannot be 0")
          caller:SelectAll()
          FindBestFocus(caller)
          return
        end
        GMA.set_global(C.GVars.mxstart, caller.Content)
      end
    elseif caller == settings_elements.RefreshRate then
      if caller.Content ~= "" then
        local num = tonumber(caller.Content)
        if num and num == 0 then
          caller.Content = "1"
          SignalTable.show_warning(caller, "Cannot be 0")
          caller:SelectAll()
          FindBestFocus(caller)
          return
        end
        GMA.set_global(C.GVars.refresh, caller.Content)
      end
    end
  end
end

-------------
-- WARNING --
-------------

SignalTable.show_warning = function(caller, status)
  local ov = GetTopOverlay(1)
  Printf(tostring(ov.Name))
  local warn = ov:FindRecursive("TitleWarningButton")
  Printf(tostring(warn.Name))
  --[[   if UI.is_valid_item(C.UI_SETTINGS, "screenOV") then
    warn = C.UI_SETTINGS_WARNING
  else
    warn = C.UI_MENU_WARNING
  end ]]
  if caller and status and status == "Name is too long (maximum 2 characters)" then
    if GMA.get_global(C.GVars.timing) == 1 then
      status = "Timing Master 1-50"
    elseif GMA.get_global(C.GVars.speed) == 1 then
      status = "Speed Master 1-16"
    else
      status = "Maximum 2 Digits"
    end
  end
  warn.ShowAnimation(status)

  if PluginError then
    PluginError = nil
    coroutine.yield(0.05)
    FindNextFocus(true)
  end
end

SignalTable.show_apply = function(caller)
end

SignalTable.icon_hover = function()
  C.CMD_ICON.ICONOFFSETV = -5
  C.CMD_ICON.ICONSCALE = 1.5
end

SignalTable.icon_unhover = function()
  C.CMD_ICON.ICONOFFSETV = 0
  C.CMD_ICON.ICONSCALE = 1
end

-- Debug
function S.echo(message)
  Echo("SIGNALS READY!")
end

return S
