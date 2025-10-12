-- ---------------------------------------------------------------------------
-- MODULE: state
-- PURPOSE: Save and load plugin state from global variables
-- ---------------------------------------------------------------------------

local M = {}

-- Field configuration for UI state management
local UI_FIELDS = {
  "MasterValue",
  "Matricks1Value", "Matricks1Rate",
  "Matricks2Value", "Matricks2Rate",
  "Matricks3Value", "Matricks3Rate",
  "MatricksPrefixValue", "OverallScaleValue"
}

local MATRICKS_BUTTONS = {
  "Matricks1Button", "Matricks2Button", "Matricks3Button", "MatricksPrefixButton"
}

local MATRICKS_MAPPING = {
  Matricks1Button = { "Matricks1Value", "Matricks1Rate" },
  Matricks2Button = { "Matricks2Value", "Matricks2Rate" },
  Matricks3Button = { "Matricks3Value", "Matricks3Rate" },
  MatricksPrefixButton = { "MatricksPrefixValue" },
}


-- ---------------------------------------------------------------------------
-- SAVE STATE
-- ---------------------------------------------------------------------------

-- Unified save function for both UI and settings state
-- params: helpers module, overlay
function M.save_state(helpers, overlay)
  -- Save UI fields
  for _, name in ipairs(UI_FIELDS) do
    local el = overlay:FindRecursive(name)
    if el then
      if name == "OverallScaleValue" then
        helpers.set_global("TM_" .. name, el.Text or "")
      else
        helpers.set_global("TM_" .. name, el.Content or "")
      end
    end
  end
  
  -- Save timing / speed master
  local timing = overlay:FindRecursive("TimingMaster")
  local speed = overlay:FindRecursive("SpeedMaster")
  if timing then helpers.set_global("TM_TimingMaster", timing.State or 1) end
  if speed then helpers.set_global("TM_SpeedMaster", speed.State or 0) end
  
  -- Save matricks buttons
  for _, name in ipairs(MATRICKS_BUTTONS) do
    local el = overlay:FindRecursive(name)
    if el then helpers.set_global("TM_" .. name, el.State or 0) end
  end
  
  -- Save settings fields
  local matricks_start = overlay:FindRecursive("MatricksStartIndex")
  if matricks_start then
    helpers.set_global("TM_MatricksStartIndex", matricks_start.Content or "")
  end
  
  local refresh_rate = overlay:FindRecursive("RefreshRateValue")
  if refresh_rate then
    helpers.set_global("TM_RefreshRateValue", refresh_rate.Content or "1")
  end
  
  -- Save fade settings
  local fade_amount = overlay:FindRecursive("FadeAmount")
  if fade_amount then
    local size = fade_amount[2][1]:Get("Size")
    
    -- Save fade button text and font
    local fade_less = overlay:FindRecursive("FadeLess")
    local fade_more = overlay:FindRecursive("FadeMore")
    
    if fade_less then
      local txt = fade_less:Get("Text")
      local font = fade_less:Get("Font", Enums.Roles.Default)
      local enabled = fade_less:Get("Enabled", Enums.Roles.Default)
      helpers.set_global("TM_FadeLessText", txt)
      helpers.set_global("TM_FadeLessFont", font)
      helpers.set_global("TM_FadeToggle", (enabled == "Yes") and "1" or "0")
    end
    
    if fade_more then
      local txt = fade_more:Get("Text")
      local font = fade_more:Get("Font", Enums.Roles.Default)
      helpers.set_global("TM_FadeMoreText", txt)
      helpers.set_global("TM_FadeMoreFont", font)
      
      if size then
        -- Convert 200-500 range to 0.3-0.7
        local normalized = (size - 200) / 300
        helpers.set_global("TM_FadeValue", tostring(0.3 + (normalized * 0.4)))
      end
    end
  end
end


-- ---------------------------------------------------------------------------
-- LOAD STATE
-- ---------------------------------------------------------------------------

-- Unified load function for both UI and settings state
-- params: helpers module, overlay, plugin_running flag
function M.load_state(helpers, overlay, plugin_running)
  -- Load plugin state (on/off)
  local on = overlay:FindRecursive("PluginOn")
  local off = overlay:FindRecursive("PluginOff")
  if on and off then
    -- This will be connected to signal handlers in main file
    -- Just set visual state here
    on.State = plugin_running and 1 or 0
    off.State = plugin_running and 0 or 1
  end
  
  -- Load UI fields
  for _, name in ipairs(UI_FIELDS) do
    local el = overlay:FindRecursive(name)
    if el then
      if name == "OverallScaleValue" then
        local stored = helpers.get_global("TM_" .. name, el.Text or "")
        el.Text = stored
      else
        local stored = helpers.get_global("TM_" .. name, el.Content or "")
        el.Content = stored
      end
    end
  end
  
  -- Load timing / speed master
  local timing = overlay:FindRecursive("TimingMaster")
  local speed = overlay:FindRecursive("SpeedMaster")
  if timing then timing.State = tonumber(helpers.get_global("TM_TimingMaster", timing.State or 1)) end
  if speed then speed.State = tonumber(helpers.get_global("TM_SpeedMaster", speed.State or 0)) end
  
  -- Load matricks buttons and enable/disable related fields
  for btn, related in pairs(MATRICKS_MAPPING) do
    local b = overlay:FindRecursive(btn)
    if b then
      local saved = tonumber(helpers.get_global("TM_" .. btn, b.State or 0))
      b.State = saved
      local enable = (saved == 1) and "Yes" or "No"
      
      for _, fn in ipairs(related) do
        local f = overlay:FindRecursive(fn)
        if f then f.Enabled = enable end
      end
    end
  end
  
  -- Load settings fields
  local matricks_start = overlay:FindRecursive("MatricksStartIndex")
  if matricks_start then
    matricks_start.Content = helpers.get_global("TM_MatricksStartIndex", matricks_start.Content or "1")
  end
  
  local refresh_rate = overlay:FindRecursive("RefreshRateValue")
  if refresh_rate then
    refresh_rate.Content = helpers.get_global("TM_RefreshRateValue", refresh_rate.Content or "1")
  end
  
  -- Load fade settings
  local fade_amount = overlay:FindRecursive("FadeAmount")
  if fade_amount then
    local stored = tonumber(helpers.get_global("TM_FadeValue", "0.5")) or 0.5
    -- Map 0.3-0.7 to 200-500 range
    local size = 200 + ((stored - 0.3) / 0.4 * 300)
    fade_amount[2][1]:Set("Size", math.floor(size + 0.5)) -- Round to nearest integer
  end
  
  -- Load fade button text and font
  local fade_less = overlay:FindRecursive("FadeLess")
  local fade_more = overlay:FindRecursive("FadeMore")
  if fade_less then
    fade_less.Text = helpers.get_global("TM_FadeLessText")
    fade_less.Font = helpers.get_global("TM_FadeLessFont")
    fade_less.Enabled = (helpers.get_global("TM_FadeToggle", "1") == "1") and "Yes" or "No"
  end
  if fade_more then
    fade_more.Text = helpers.get_global("TM_FadeMoreText")
    fade_more.Font = helpers.get_global("TM_FadeMoreFont")
  end
end


return M
