-- ---------------------------------------------------------------------------
-- MODULE: constants
-- PURPOSE: Plugin configuration and constants
-- ---------------------------------------------------------------------------

local M = {}

-- ---------------------------------------------------------------------------
-- PLUGIN METADATA
-- ---------------------------------------------------------------------------

M.PLUGIN_NAME = "TimeMAtricks"
M.PLUGIN_VERSION = "BETA 0.9.4"
M.UI_CMD_ICON_NAME = M.PLUGIN_NAME .. "Icon"
M.UI_MENU_NAME = M.PLUGIN_NAME .. " Menu"
M.UI_SETTINGS_NAME = "Settings Menu"


-- ---------------------------------------------------------------------------
-- UI COLOR DEFINITIONS
-- ---------------------------------------------------------------------------

M.colors = {
  text = {
    white = "Global.Text",
    black = "Global.Darkened",
  },
  background = {
    default = "Overlay.FrameColor",
    dark = "Overlay.Background",
    on = "Global.WarningText",
    off = "Global.Running",
    fade = "ProgLayer.Fade",
    delay = "ProgLayer.Delay",
    transparent25 = "Global.Transparent25",
  },
  button = {
    default = "Button.Background",
    clear = "Button.BackgroundClear",
    please = "Button.BackgroundPlease",
  },
  icon = {
    active = "Button.ActiveIcon",
    inactive = "Button.Icon",
  },
}


-- ---------------------------------------------------------------------------
-- ICON DEFINITIONS
-- ---------------------------------------------------------------------------

M.icons = {
  matricks = "object_matricks",
  star = "star",
  cross = "close",
}


-- ---------------------------------------------------------------------------
-- CORNER STYLE DEFINITIONS
-- ---------------------------------------------------------------------------

M.corners = {
  none = "corner0",
  topleft = "corner1",
  topright = "corner2",
  bottomleft = "corner4",
  bottomright = "corner8",
  top = "corner3",
  bottom = "corner12",
  left = "corner5",
  right = "corner10",
  all = "corner15",
}


-- ---------------------------------------------------------------------------
-- FADE SLIDER SETTINGS
-- ---------------------------------------------------------------------------

M.fade = {
  min_size = 200,
  max_size = 500,
  step = 60,
  min_value = 0.3,
  max_value = 0.7,
}


-- ---------------------------------------------------------------------------
-- MASTER LIMITS
-- ---------------------------------------------------------------------------

M.master_limits = {
  timing = { min = 1, max = 50 },
  speed = { min = 1, max = 16 },
}


-- ---------------------------------------------------------------------------
-- GLOBAL VARIABLE NAMES
-- ---------------------------------------------------------------------------

M.global_vars = {
  "TM_MasterValue",
  "TM_TimingMaster",
  "TM_SpeedMaster",
  "TM_Matricks1Value",
  "TM_Matricks2Value",
  "TM_Matricks3Value",
  "TM_Matricks1Rate",
  "TM_Matricks2Rate",
  "TM_Matricks3Rate",
  "TM_Matricks1Button",
  "TM_Matricks2Button",
  "TM_Matricks3Button",
  "TM_MatricksPrefixValue",
  "TM_MatricksPrefixButton",
  "TM_MatricksStartIndex",
  "TM_RefreshRateValue",
  "TM_FadeValue",
  "TM_FadeToggle",
  "TM_FadeLessText",
  "TM_FadeLessFont",
  "TM_FadeMoreText",
  "TM_FadeMoreFont",
  "TM_OverallScaleValue",
  "TM_FirstStart",
}


return M
