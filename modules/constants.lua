---@diagnostic disable: redundant-parameter

C = {}

C.PLUGIN_NAME = "TimeMAtricks"
C.PLUGIN_VERSION = "Beta 0.0.0"
C.CMD_ICON_NAME = C.PLUGIN_NAME .. "_Icon"
C.UI_MENU_NAME = C.PLUGIN_NAME .. "_Menu"
C.UI_SETTINGS_NAME = C.PLUGIN_NAME .. "_Settings"


C.colors = {
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
C.icons = {
  matricks = 'object_matricks',
  star = 'star',
  cross = 'close',
}
C.corners = {
  none = 'corner0',
  topleft = 'corner1',
  topright = 'corner2',
  bottomleft = 'corner4',
  bottomright = 'corner8',
  top = 'corner3',
  bottom = 'corner12',
  left = 'corner5',
  right = 'corner10',
  all = 'corner15',
}

C.Global_Vars = {
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
  "TM_FirstStart"
}

function C.echo(message)
  Echo("CONSTANTS READY!")
end

C.cmdLN = GetDisplayByIndex(1).CmdLineSection
C.screenOV = GetDisplayByIndex(1).ScreenOverlay

return C
