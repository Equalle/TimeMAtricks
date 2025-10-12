---@diagnostic disable: redundant-parameter
-- ===========================================================================
-- TimeMAtricks Plugin - Modular Version
-- ===========================================================================

local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

-- Plugin state
local pluginAlive = nil
local pluginRunning = false
local pluginError = nil

-- Module references (will be loaded)
local C, H, S, X, U, M


-- ---------------------------------------------------------------------------
-- MODULE LOADING
-- ---------------------------------------------------------------------------

local function load_modules()
  -- Get paths
  local plugin_lib = GetPath(Enums.PathType.PluginLibrary)
  local module_dir = plugin_lib .. "/TimeMAtricks_modules/"
  
  -- Determine source path
  local source_dir = "/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks/modules/"
  
  -- Create module directory and copy files
  os.execute("mkdir -p \"" .. module_dir .. "\"")
  os.execute("cp \"" .. source_dir .. "\"*.lua \"" .. module_dir .. "\"")
  
  Echo("Loading modules from: " .. module_dir)
  
  -- Load all modules
  local constants = dofile(module_dir .. "constants.lua")
  local helpers = dofile(module_dir .. "helpers.lua")
  local state = dofile(module_dir .. "state.lua")
  local ui_xml = dofile(module_dir .. "ui_xml.lua")
  local ui = dofile(module_dir .. "ui.lua")
  local matricks = dofile(module_dir .. "matricks.lua")
  
  Echo("Modules loaded successfully")
  
  return constants, helpers, state, ui_xml, ui, matricks
end

-- Load modules at startup
C, H, S, X, U, M = load_modules()


-- ---------------------------------------------------------------------------
-- SIGNAL TABLE - Event Handlers
-- ---------------------------------------------------------------------------

signalTable.cmdbar_clicked = function()
  if not H.is_valid_ui_item(C.UI_MENU_NAME, "ScreenOverlay") then
    U.create_menu(C, H, S, X, signalTable, myHandle, pluginRunning)
    local ov = GetTopOverlay(1)
    FindBestFocus(ov)
  else
    local menu = GetDisplayByIndex(1).ScreenOverlay:Ptr(
      H.get_ui_item_index(C.UI_MENU_NAME, "ScreenOverlay"))
    if menu then menu.Visible = "Yes" end
  end
end


signalTable.open_settings = function(caller)
  U.create_settings_menu(C, H, S, X, signalTable, myHandle)
end


signalTable.plugin_off = function(caller)
  pluginRunning = false
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  if ov then
    local on = ov:FindRecursive("PluginOn")
    local off = ov:FindRecursive("PluginOff")
    local titleicon = ov:FindRecursive("TitleButton")
    if not on or not off then return end
    
    on.BackColor, off.BackColor = C.colors.button.default, C.colors.button.clear
    on.TextColor, off.TextColor = C.colors.text.white, C.colors.icon.active
    titleicon.IconColor = C.colors.icon.inactive
  end
  
  local cmdicon = GetDisplayByIndex(1).CmdLineSection:FindRecursive(C.UI_CMD_ICON_NAME)
  if cmdicon then
    cmdicon.IconColor = C.colors.icon.inactive
  end
end


signalTable.plugin_on = function(caller)
  pluginRunning = true
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local off = ov:FindRecursive("PluginOff")
  local on = ov:FindRecursive("PluginOn")
  local titleicon = ov:FindRecursive("TitleButton")
  local cmdicon = GetDisplayByIndex(1).CmdLineSection:FindRecursive(C.UI_CMD_ICON_NAME)
  
  if not on or not off then return end
  
  off.BackColor, on.BackColor = C.colors.button.default, C.colors.button.please
  off.TextColor, on.TextColor = C.colors.text.white, C.colors.icon.active
  titleicon.IconColor = C.colors.icon.active
  cmdicon.IconColor = C.colors.icon.active
end


signalTable.master_swap = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local timing = ov:FindRecursive("TimingMaster")
  local speed = ov:FindRecursive("SpeedMaster")
  local master = ov:FindRecursive("MasterValue")
  
  if master.Content == "" then
    local is_timing = caller == timing
    timing.State = is_timing and 1 or 0
    speed.State = is_timing and 0 or 1
    master.Content = ""
    S.save_state(H, ov)
    return
  end
  
  if caller.State ~= 1 then
    if Confirm("Override!", "Are you sure you want to override\nyour currently entered Master and use " .. caller.Name .. "?", nil, true) then
      local is_timing = caller == timing
      timing.State = is_timing and 1 or 0
      speed.State = is_timing and 0 or 1
      master.Content = ""
      S.save_state(H, ov)
    end
  end
end


signalTable.matricks_toggle = function(caller)
  local mapping = {
    Matricks1Button = { "Matricks1Value", "Matricks1Rate" },
    Matricks2Button = { "Matricks2Value", "Matricks2Rate" },
    Matricks3Button = { "Matricks3Value", "Matricks3Rate" },
    MatricksPrefixButton = { "MatricksPrefixValue" },
  }
  
  local related = mapping[caller.Name] or {}
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local new_state = (caller:Get("State") == 1) and 0 or 1
  caller:Set("State", new_state)
  
  local enable = (new_state == 1) and "Yes" or "No"
  for _, name in ipairs(related) do
    local el = ov:FindRecursive(name)
    if el then
      el.Enabled = enable
      if enable == "Yes" and name:match("Value") then
        FindBestFocus(el)
      else
        FindBestFocus(ov)
      end
    end
  end
  
  -- Handle adding/removing prefix from existing TimeMAtricks triplets
  if caller.Name == "MatricksPrefixButton" then
    local prefix_field = ov:FindRecursive("MatricksPrefixValue")
    local prefix = prefix_field and (prefix_field.Content or "") or ""
    if prefix ~= "" then
      M.handle_prefix_toggle(H, new_state, prefix)
    end
  end
  
  S.save_state(H, ov)
end


signalTable.sanitize = function(caller)
  local before = caller.Content or ""
  local after = before
  
  if caller.Name == "MasterValue" then
    after = after:gsub("[^%d]", "")
    
    if after ~= "" then
      local num = tonumber(after)
      if num then
        if H.get_global("TM_TimingMaster") == 1 then
          if num < C.master_limits.timing.min then
            after = C.master_limits.timing.min
          elseif num > C.master_limits.timing.max then
            after = C.master_limits.timing.max
          end
        elseif H.get_global("TM_SpeedMaster", "0") == 1 then
          if num < C.master_limits.speed.min then
            after = C.master_limits.speed.min
          elseif num > C.master_limits.speed.max then
            after = C.master_limits.speed.max
          end
        end
      end
    end
  else
    after = H.sanitize_text(before)
  end
  
  if before ~= after then
    caller.Content = after
    if caller.HasFocus then
      Keyboard(1, "press", "End")
      Keyboard(1, "release", "End")
      if caller.Name == "MasterValue" and H.get_global("TM_SpeedMaster") == 1 then
        signalTable.ShowWarning(caller, "Speed Master: 1-16")
      elseif caller.Name == "MasterValue" and H.get_global("TM_TimingMaster") == 1 then
        signalTable.ShowWarning(caller, "TimingMaster: 1-50")
      else
        signalTable.ShowWarning(caller, "Allowed format: x.xx")
      end
    end
  end
end


signalTable.ShowWarning = function(caller, status, creator)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local ov2 = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_SETTINGS_NAME)
  
  if ov == caller:Parent():Parent():Parent() then
    local ti = ov.TitleBar.WarningButton
    ti.ShowAnimation(status)
  elseif ov2 == caller:Parent():Parent():Parent() then
    local ti = ov2.TitleBar.WarningButton
    ti.ShowAnimation(status)
  end
  
  if pluginError then
    pluginError = nil
    coroutine.yield(0.2)
    FindNextFocus(true)
  end
end


signalTable.ShowWarning2 = function(caller, status, creator)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local ov2 = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_SETTINGS_NAME)
  
  if ov == caller:Parent():Parent():Parent() then
    local ti = ov:FindRecursive("WarningButton2")
    ti.ShowAnimation(status)
  elseif ov2 == caller:Parent():Parent():Parent() then
    local ti = ov2:FindRecursive("WarningButton2")
    ti.ShowAnimation(status)
  end
end


signalTable.close = function(caller)
  if caller and caller.Name == "Close" then
    Keyboard(1, "press", "Escape")
    Keyboard(1, "release", "Escape")
    local ov = GetDisplayByIndex(1).ScreenOverlay
    local menu = ov:FindRecursive(C.UI_MENU_NAME)
    menu.Visible = "Yes"
  else
    local ov = GetDisplayByIndex(1).ScreenOverlay
    local menu = ov:FindRecursive(C.UI_MENU_NAME)
    if menu then
      menu.Visible = "Yes"
    end
  end
end


signalTable.apply = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  if ov then S.save_state(H, ov) end
  
  signalTable.ShowWarning2(caller, "")
  FindNextFocus()
end


signalTable.Confirm = function(caller)
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  if caller == overlay.FindRecursive(C.UI_MENU_NAME) then
    signalTable.close(caller)
  elseif caller == overlay.FindRecursive(C.UI_SETTINGS_NAME) then
    signalTable.close(caller)
  end
end


signalTable.LineEditSelectAll = function(caller)
  if not caller then return end
  caller:SelectAll()
  
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  if not ov then return end
  
  local field_names = {
    "Matricks1Value",
    "Matricks2Value",
    "Matricks3Value",
    "Matricks1Rate",
    "Matricks2Rate",
    "Matricks3Rate",
    "MatricksPrefixValue",
    "MasterValue"
  }
  
  local function is_rate(name)
    return name:match("^Matricks%dRate$")
  end
  
  for _, name in ipairs(field_names) do
    if name ~= caller.Name and not is_rate(name) then
      local el = ov:FindRecursive(name)
      if el then
        if el.HasFocus then el:Deselect() end
        
        local saved = H.get_global("TM_" .. name, el.Content or "")
        if (el.Content or "") ~= saved then
          el.Content = saved
          signalTable.ShowWarning(caller, "NOT SAVED! Restored saved value")
        end
      end
    end
  end
end


signalTable.LineEditDeSelect = function(caller)
  caller.Deselect()
end


signalTable.ExecuteOnEnter = function(caller, dummy, keyCode)
  if caller.HasFocus and keyCode == Enums.KeyboardCodes.Enter then
    signalTable.LineEditDeSelect(caller)
    
    local n = caller and caller.Name
    if n == "Matricks1Value" or n == "Matricks2Value" or n == "Matricks3Value" or n == "MatricksPrefixValue" then
      M.matricks_handler(H, caller, signalTable.ShowWarning)
      local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
      if ov then S.save_state(H, ov) end
    elseif n == "MasterValue" or n == "RefreshRateValue" or n == "MatricksStartIndex" then
      local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
      if ov then S.save_state(H, ov) end
    end
    
    if caller.Name == "Apply" then
      signalTable.apply(caller)
      FindNextFocus()
    elseif caller.Name == "Close" then
      signalTable.close(caller)
    else
      FindNextFocus()
    end
  end
end


signalTable.reset_overallrate = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local rate = ov:FindRecursive("OverallScaleValue")
  rate.Text = 1
  S.save_state(H, ov)
end


signalTable.rate_mod = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local rate = ov:FindRecursive("OverallScaleValue")
  
  if caller.Name == "HT" and tonumber(rate:Get("Text")) > 0.125 then
    local new_value = tonumber(rate.Text or "1") * 0.5
    if math.floor(new_value) == new_value then
      rate.Text = tostring(math.floor(new_value))
    else
      rate.Text = tostring(new_value)
    end
  elseif caller.Name == "DT" and tonumber(rate:Get("Text")) < 8 then
    local new_value = tonumber(rate.Text or "1") * 2
    if math.floor(new_value) == new_value then
      rate.Text = tostring(math.floor(new_value))
    else
      rate.Text = tostring(new_value)
    end
  end
  
  S.save_state(H, ov)
end


signalTable.fade_adjust = function(caller)
  local direction
  if caller.Name == "FadeLess" then
    direction = -1
  elseif caller.Name == "FadeMore" then
    direction = 1
    
    -- If FadeLess is disabled, enable it when clicking FadeMore
    local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
    local fade_less = ov:FindRecursive("FadeLess")
    if fade_less:Get("Enabled", Enums.Roles.Default) == "No" then
      fade_less:Set("Enabled", "Yes")
      H.set_global("TM_FadeToggle", "1")
      U.update_fade_buttons(C, H, ov)
    end
  else
    return
  end
  
  U.fade_adjust(C, H, direction, caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  if ov then S.save_state(H, ov) end
end


signalTable.fade_hold = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
  local less = ov:FindRecursive("FadeLess")
  local en = less:Get("Enabled", Enums.Roles.Default)
  
  if en == "Yes" then
    less:Set("Enabled", "No")
    H.set_global("TM_FadeToggle", "0")
    U.update_fade_buttons(C, H, ov)
    S.save_state(H, ov)
  elseif en == "No" then
    less:Set("Enabled", "Yes")
    H.set_global("TM_FadeToggle", "1")
    U.update_fade_buttons(C, H, ov)
    S.save_state(H, ov)
  end
end


-- ---------------------------------------------------------------------------
-- MAIN LOOP
-- ---------------------------------------------------------------------------

local function plugin_loop()
  pluginAlive = true
  
  if pluginRunning then
    local mx_pool = DataPool(1).Matricks
    local mstr = MasterPool()
    
    -- Get all values from globals
    local v = {
      m1t = H.get_global("TM_Matricks1Button", "") or 0,
      m1r = H.get_global("TM_Matricks1Rate", "0.25") or 0.25,
      m1v = H.get_global("TM_Matricks1Value", "") or "",
      m2t = H.get_global("TM_Matricks2Button", "") or 0,
      m2r = H.get_global("TM_Matricks2Rate", "0.5") or 0.5,
      m2v = H.get_global("TM_Matricks2Value", "") or "",
      m3t = H.get_global("TM_Matricks3Button", "") or 0,
      m3r = H.get_global("TM_Matricks3Rate", "1") or 1,
      m3v = H.get_global("TM_Matricks3Value", "") or "",
      mpt = H.get_global("TM_MatricksPrefixButton", "") or 0,
      mpv = H.get_global("TM_MatricksPrefixValue", "") or "",
      mv = H.get_global("TM_MasterValue", "") or "",
      mt = H.get_global("TM_TimingMaster", "") or 0,
      ms = H.get_global("TM_SpeedMaster", "") or 0,
      os = H.get_global("TM_OverallScaleValue", "1") or 1,
      ft = H.get_global("TM_FadeToggle", "0") or 0,
      fv = H.get_global("TM_FadeValue", "0.5") or 0.5,
    }
    
    if (v.mv ~= nil and v.mv ~= "") and ((tonumber(v.mt) == 1) or (tonumber(v.ms) == 1)) then
      local m
      if v.mt == 1 then
        m = mstr.Timing
      elseif v.ms == 1 then
        m = mstr.Speed
      end
      
      local mstr_item = m and m:Ptr(tonumber(v.mv))
      if mstr_item then
        local normed = mstr_item:GetFader({}) or 0
        
        if v.mt == 1 then
          normed = normed / 10
          normed = math.floor(normed * 100 + 0.5) / 100
        elseif v.ms == 1 then
          local bpm = H.bpm_quartic(normed)
          normed = 60 / bpm
          normed = math.floor(normed * 100 + 0.5) / 100
        end
        
        normed = normed / v.os
        
        -- Apply to active matricks
        M.apply_to_triplets(H, mx_pool, v, normed)
      end
    end
  end
  
  local refresh_rate = tonumber(H.get_global("TM_RefreshRateValue", "1")) or 1
  coroutine.yield(refresh_rate)
end


local function plugin_kill()
  pluginAlive = false
  signalTable.plugin_off()
  
  local ov = GetDisplayByIndex(1).ScreenOverlay
  local menu = ov:FindRecursive(C.UI_MENU_NAME)
  if menu then
    FindBestFocus(menu)
    Keyboard(1, "press", "Escape")
    Keyboard(1, "release", "Escape")
  end
  
  U.delete_cmd_line_icon(C)
  
  -- Clean up XML files
  local temp = GetPath("temp", false)
  local ui_xml = temp .. "/TimeMAtricks_UI.xml"
  local settings_xml = temp .. "/TimeMAtricks_Settings_UI.xml"
  
  if FileExists(ui_xml) then
    os.remove(ui_xml)
    Echo("Removed " .. ui_xml)
  end
  if FileExists(settings_xml) then
    os.remove(settings_xml)
    Echo("Removed " .. settings_xml)
  end
  
  -- Clean up module copies
  local plugin_lib = GetPath(Enums.PathType.PluginLibrary)
  os.execute("rm -rf \"" .. plugin_lib .. "/TimeMAtricks_modules\"")
  Echo("Cleaned up module files")
end


-- ---------------------------------------------------------------------------
-- MAIN ENTRY POINT
-- ---------------------------------------------------------------------------

local function main()
  if not pluginAlive or nil then
    if H.is_valid_ui_item(C.UI_CMD_ICON_NAME, "CmdLineSection") then
      pluginAlive = true
    else
      pluginAlive = false
      U.create_cmd_line_icon(C, myHandle)
      
      -- Create panic macro if doesn't exist
      if not DataPool(1).Macros:FindRecursive("TimeMAtricks Reset") then
        if not U.create_panic_macro(C) then
          ErrPrintf("Failed to create panic macro")
        end
      end
    end
    
    signalTable.cmdbar_clicked()
    
    -- First launch message
    local frst_strt = H.get_global("TM_FirstStart", nil)
    if not frst_strt then
      local messageBoxSettings = {
        title = "First Launch",
        message = "Press the Settings button at the top to configure the starting MAtricks pool number.",
        commands = { { value = 1, name = "Ok" } },
        icon = "QuestionMarkIcon",
        timeout = 10000,
        backColor = "Window.Plugins",
      }
      MessageBox(messageBoxSettings)
      
      local menu = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
      local set_btn = menu:FindRecursive("SettingsBtn")
      if set_btn then
        FindNextFocus(true)
        FindNextFocus(true)
      end
    end
    
    H.set_global("TM_FirstStart", true)
    Timer(plugin_loop, 0, 0, plugin_kill)
  else
    signalTable.cmdbar_clicked()
    return
  end
end

return main
