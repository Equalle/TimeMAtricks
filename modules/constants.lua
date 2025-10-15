---@diagnostic disable: redundant-parameter

C = {}

C.PLUGIN_NAME = "TimeMAtricks"
C.PLUGIN_VERSION = "Beta 0.0.0"
C.CMD_ICON_NAME = C.PLUGIN_NAME .. "_Icon"
C.UI_MENU_NAME = C.PLUGIN_NAME .. "_Menu"
C.UI_SETTINGS_NAME = C.PLUGIN_NAME .. "_Settings"
C.UI_MENU = nil


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

C.GVars = {
  "TM_mvalue",
  "TM_timing",
  "TM_speed",
  "TM_mx1name",
  "TM_mx2name",
  "TM_mx3name",
  "TM_mx1rate",
  "TM_mx2rate",
  "TM_mx3rate",
  "TM_mx1",
  "TM_mx2",
  "TM_mx3",
  "TM_prefixname",
  "TM_prefix",
  "TM_mxstart",
  "TM_refresh",
  "TM_fadeamount",
  "TM_fade",
  "TM_ovrate",
  "TM_firststart"
}

function C.echo(message)
  Echo("CONSTANTS READY!")
end

C.cmdLN = GetDisplayByIndex(1).CmdLineSection
C.screenOV = GetDisplayByIndex(1).ScreenOverlay

return C
