-- ---------------------------------------------------------------------------
-- MODULE: ui
-- PURPOSE: UI creation and management functions
-- ---------------------------------------------------------------------------

local M = {}


-- ---------------------------------------------------------------------------
-- UI ELEMENT CONFIGURATION
-- ---------------------------------------------------------------------------

-- Generic function to configure UI elements
-- element_type: "button", "checkbox", "textbox", "hold"
function M.add_ui_element(name, overlay, element_type, options, my_handle)
  local el = overlay:FindRecursive(name)
  if not el then
    local type_desc = element_type == "checkbox" and "Box" 
      or element_type == "textbox" and "Textbox" 
      or "Button"
    ErrPrintf(type_desc .. " not found: " .. tostring(name))
    return false
  end
  
  el.PluginComponent = my_handle
  
  -- Handle different element types
  if element_type == "button" or element_type == "checkbox" then
    el.Clicked = options.clicked or ""
  end
  
  if element_type == "hold" then
    el.MouseDownHold = options.hold or ""
  end
  
  if element_type == "checkbox" and options.state ~= nil then
    el.State = options.state
  end
  
  if element_type == "textbox" and options.content ~= nil then
    el.Content = options.content
  end
  
  if options.enabled ~= nil then
    el.Enabled = options.enabled
  else
    el.Enabled = "Yes"
  end
  
  return true
end


-- ---------------------------------------------------------------------------
-- FADE MANAGEMENT
-- ---------------------------------------------------------------------------

-- Adjust fade slider amount
function M.fade_adjust(constants, helpers, direction, caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(constants.UI_MENU_NAME)
  local sl = ov:FindRecursive("FadeAmount")
  local less = ov:FindRecursive("FadeLess")
  local more = ov:FindRecursive("FadeMore")
  local wmore = ov:FindRecursive("FadeMoreWarning")
  local wless = ov:FindRecursive("FadeLessWarning")
  
  if sl then
    local cur = tonumber(sl[2][1]:Get("Size"))
    local min, max, step = constants.fade.min_size, constants.fade.max_size, constants.fade.step
    local new = cur + (step * direction)
    
    if new >= min and new <= max then
      sl[2][1]:Set("Size", new)
      local ch_cur = tonumber(sl[2][1]:Get("Size"))
      local old = tonumber(helpers.get_global("TM_FadeValue", 0.5)) or 0.5
      local delta = 0.1 * direction
      local updated = old + delta
      
      if (direction == -1 and ch_cur >= min) or (direction == 1 and ch_cur <= max) then
        helpers.set_global("TM_FadeValue", tostring(updated))
      end
      
      if caller.Name == "FadeLess" and tonumber(ch_cur) == min + 30 then
        less.Text = "MIN"
        less.Font = "Medium20"
        more.Text = "Fade More"
        more.Font = "Regular18"
        wless.ShowAnimation()
      elseif caller.Name == "FadeMore" and tonumber(ch_cur) == max - 30 then
        more.Text = "MAX"
        more.Font = "Medium20"
        less.Text = "Fade Less"
        less.Font = "Regular18"
        wmore.ShowAnimation()
      else
        less.Text = "Fade Less"
        less.Font = "Regular18"
        more.Text = "Fade More"
        more.Font = "Regular18"
      end
    end
  end
end


-- Update fade button text based on current state
function M.update_fade_buttons(constants, helpers, overlay)
  local fade_less = overlay:FindRecursive("FadeLess")
  local fade_more = overlay:FindRecursive("FadeMore")
  local fade_amount = overlay:FindRecursive("FadeAmount")
  local min, max = constants.fade.min_size + 30, constants.fade.max_size - 30
  
  if fade_less and fade_more and fade_amount then
    local size = fade_amount[2][1]:Get("Size")
    if fade_less:Get("Enabled", Enums.Roles.Default) == "No" or fade_more:Get("Enabled", Enums.Roles.Default) == "No" then
      fade_less:Set("Text", "Fade Disabled")
      fade_more:Set("Text", "(Click to enable)")
    elseif tonumber(size) == min then
      fade_less:Set("Text", "MIN")
      fade_less.Font = "Medium20"
      fade_more:Set("Text", "Fade More")
      fade_more.Font = "Regular18"
    elseif tonumber(size) == max then
      fade_more:Set("Text", "MAX")
      fade_more.Font = "Medium20"
      fade_less:Set("Text", "Fade Less")
      fade_less.Font = "Regular18"
    else
      fade_less:Set("Text", "Fade Less")
      fade_less.Font = "Regular18"
      fade_more:Set("Text", "Fade More")
      fade_more.Font = "Regular18"
    end
  end
end


-- ---------------------------------------------------------------------------
-- COMMAND BAR ICON
-- ---------------------------------------------------------------------------

-- Create command bar icon
function M.create_cmd_line_icon(constants, my_handle)
  local cmdbar = GetDisplayByIndex(1).CmdLineSection
  local last_cols = tonumber(cmdbar:Get("Columns"))
  local cols = last_cols + 1
  cmdbar.Columns = cols
  cmdbar[2][cols].SizePolicy = "Fixed"
  cmdbar[2][cols].Size = 50
  
  local tm_icon = cmdbar:Append('Button')
  tm_icon.Name = constants.UI_CMD_ICON_NAME
  tm_icon.Anchors = { left = cols - 2 }
  tm_icon.W = 49
  tm_icon.PluginComponent = my_handle
  tm_icon.Clicked = 'cmdbar_clicked'
  tm_icon.Icon = constants.icons.matricks
  tm_icon.IconColor = constants.colors.icon.inactive
  tm_icon.Tooltip = "TimeMAtricks Plugin"
  
  local tri = cmdbar:FindRecursive("RightTriangle")
  if tri then
    tri.Anchors = { left = cols - 1 }
  end
  
  return tm_icon
end


-- Delete command bar icon
function M.delete_cmd_line_icon(constants)
  local cmdbar = GetDisplayByIndex(1).CmdLineSection
  local tm_icon = cmdbar:FindRecursive(constants.UI_CMD_ICON_NAME)
  
  if tm_icon then
    local icon_position = tm_icon.Anchors.left or 0
    
    -- Remove the icon
    cmdbar:Remove(tm_icon:Get("No"))
    
    -- Decrease column count
    local current_cols = tonumber(cmdbar:Get("Columns"))
    cmdbar.Columns = current_cols - 1
    
    -- Shift all items that were to the right of the removed icon
    for i = 1, cmdbar:Count() do
      local item = cmdbar:Ptr(i)
      if item and item.Anchors and item.Anchors.left then
        local item_position = item.Anchors.left
        if item_position > icon_position then
          item.Anchors = { left = item_position - 1 }
        end
      end
    end
    
    -- The triangle should now be at the last position
    local tri = cmdbar:FindRecursive("RightTriangle")
    if tri then
      tri.Anchors = { left = current_cols - 2 }
    end
  end
end


-- ---------------------------------------------------------------------------
-- PANIC MACRO
-- ---------------------------------------------------------------------------

-- Create panic macro to reset all plugin globals
function M.create_panic_macro(constants)
  local macros = DataPool().Macros
  local new_macro = macros:Acquire()
  
  if not new_macro then
    ErrPrintf("No free macro slot found")
    return false
  end
  
  new_macro:Set("Name", "TimeMAtricks Reset")
  new_macro:Set("Note", "Deletes all TimeMAtricks global variables")
  
  -- Add delete commands for all global variables
  for i, var_name in ipairs(constants.global_vars) do
    local line = new_macro:Append()
    if line then
      line:Set("Command", 'DeleteGlobalVariable "' .. var_name .. '"')
    end
  end
  
  Printf("Created 'TimeMAtricks Reset' Macro")
  Printf("Use to reset all TimeMAtricks settings")
  return true
end


-- ---------------------------------------------------------------------------
-- MAIN MENU CREATION
-- ---------------------------------------------------------------------------

-- Create main UI menu
function M.create_menu(constants, helpers, state, ui_xml, signal_table, my_handle, plugin_running)
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  local ui = overlay:Append('BaseInput')
  ui.SuppressOverlayAutoclose = "Yes"
  ui.AutoClose = "No"
  ui.CloseOnEscape = "Yes"
  
  local path, filename = ui_xml.resolve_xml_file(helpers, "ui")
  Echo("Import from " .. tostring(path) .. tostring(filename))
  
  if not path then
    ErrPrintf("UI XML file not found")
    return
  end
  
  if not ui:Import(path, filename) then
    ErrPrintf("Failed to import UI XML from " .. tostring(path) .. tostring(filename))
    return
  end
  
  ui:HookDelete(signal_table.close, ui)
  
  -- Wire up buttons
  local buttons = {
    { "SettingsBtn", "open_settings" },
    { "PluginOff", "plugin_off" },
    { "PluginOn", "plugin_on" },
    { "FadeLess", "fade_adjust" },
    { "FadeMore", "fade_adjust" },
    { "Apply", "apply" },
  }
  for _, b in ipairs(buttons) do
    if not M.add_ui_element(b[1], ui, "button", { clicked = b[2] }, my_handle) then
      ErrPrintf("error at " .. b[1])
    end
  end
  
  -- Wire up hold events
  local holds = {
    { "FadeLess", "fade_hold" },
    { "FadeMore", "fade_hold" },
  }
  for _, h in ipairs(holds) do
    if not M.add_ui_element(h[1], ui, "hold", { hold = h[2] }, my_handle) then
      ErrPrintf("error at " .. h[1])
    end
  end
  
  -- Wire up checkboxes
  local checks = {
    { "TimingMaster", "master_swap", 1 },
    { "SpeedMaster", "master_swap", 0 },
    { "Matricks1Button", "matricks_toggle", 1 },
    { "Matricks2Button", "matricks_toggle", 0 },
    { "Matricks3Button", "matricks_toggle", 0 },
    { "MatricksPrefixButton", "matricks_toggle", 0 },
  }
  for _, c in ipairs(checks) do
    if not M.add_ui_element(c[1], ui, "checkbox", { clicked = c[2], state = c[3] }, my_handle) then
      ErrPrintf("error at " .. c[1])
    end
  end
  
  -- Wire up textboxes
  local texts = {
    { "MasterValue", "text" },
    { "Matricks1Value", "text" }, { "Matricks1Rate", "text", "0.25" },
    { "Matricks2Value", "text" }, { "Matricks2Rate", "text", "0.5" },
    { "Matricks3Value", "text" }, { "Matricks3Rate", "text", "1" },
    { "MatricksPrefixValue", "text" },
  }
  for _, t in ipairs(texts) do
    if not M.add_ui_element(t[1], ui, "textbox", { content = t[3] }, my_handle) then
      ErrPrintf("error at " .. t[1])
    end
  end
  
  -- Wire up rate buttons
  local rates = {
    { "HT", "rate_mod", 1 },
    { "ResetRate", "reset_overallrate", 1 },
    { "DT", "rate_mod", 1 },
  }
  for _, r in ipairs(rates) do
    if not M.add_ui_element(r[1], ui, "button", { clicked = r[2] }, my_handle) then
      ErrPrintf("error at " .. r[1])
    end
  end
  
  -- Set plugin info
  local plugin_info = {
    { "TitleButton", constants.PLUGIN_NAME, constants.icons.matricks },
    { "Version", "Version " .. constants.PLUGIN_VERSION },
  }
  for _, p in ipairs(plugin_info) do
    local el = ui:FindRecursive(p[1])
    if el then
      el.Text = p[2] or ""
      if p[3] then
        el.Icon = p[3]
      end
    end
  end
  
  -- Set fade colors
  local less = ui:FindRecursive("FadeLess")
  less.BackColor = constants.colors.background.fade
  
  local more = ui:FindRecursive("FadeMore")
  more.BackColor = constants.colors.background.delay
  
  -- Load saved state
  state.load_state(helpers, ui, plugin_running)
  state.save_state(helpers, ui)
  
  coroutine.yield(0.1)
  
  -- Set focus
  if ui:FindRecursive("MasterValue").Content == "" then
    FindBestFocus(ui:FindRecursive("MasterValue"))
  else
    FindBestFocus(ui:FindRecursive("Matricks1Value"))
  end
end


-- ---------------------------------------------------------------------------
-- SETTINGS MENU CREATION
-- ---------------------------------------------------------------------------

-- Create settings dialog
function M.create_settings_menu(constants, helpers, state, ui_xml, signal_table, my_handle)
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  overlay:FindRecursive(constants.UI_MENU_NAME).Visible = "No"
  
  local setting = overlay:Append('BaseInput')
  setting.Name = constants.UI_SETTINGS_NAME
  setting.SuppressOverlayAutoclose = "Yes"
  setting.AutoClose = "No"
  setting.CloseOnEscape = "Yes"
  
  local path, filename = ui_xml.resolve_xml_file(helpers, "settings")
  setting:Import(path, filename)
  
  state.load_state(helpers, setting, false)
  setting:HookDelete(signal_table.close, constants.UI_SETTINGS_NAME)
  
  -- Wire up buttons
  local buttons = {
    { "CloseBtn", "close" },
    { "Close", "close" },
    { "Apply", "apply" },
  }
  for _, b in ipairs(buttons) do
    if not M.add_ui_element(b[1], setting, "button", { clicked = b[2] }, my_handle) then
      ErrPrintf("error at " .. b[1])
    end
  end
  
  -- Wire up textboxes
  local texts = {
    { "MatricksStartIndex", "text" },
    { "RefreshRateValue", "text", "1" },
  }
  for _, t in ipairs(texts) do
    if not M.add_ui_element(t[1], setting, "textbox", 
          { content = helpers.get_global("TM_MatricksStartIndex", "1") }, my_handle) then
      ErrPrintf("error at " .. t[1])
    end
  end
  
  state.load_state(helpers, setting, false)
  state.save_state(helpers, setting)
  
  coroutine.yield(0.1)
  FindBestFocus(setting:FindRecursive("MatricksStartIndex"))
end


return M
