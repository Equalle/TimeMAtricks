---@diagnostic disable: redundant-parameter

C = {}

C.PLUGIN_NAME = "TimeMAtricks"
C.PLUGIN_VERSION = "Beta 0.0.0"
C.CMD_ICON_NAME = C.PLUGIN_NAME .. "_Icon"
C.UI_MENU_NAME = C.PLUGIN_NAME .. "_Menu"
C.UI_SETTINGS_NAME = C.PLUGIN_NAME .. "_Settings"
C.CMD_ICON = nil
C.UI_MENU = nil
C.UI_SETTINGS = nil
C.UI_MENU_WARNING = nil
C.UI_SETTINGS_WARNING = nil


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
  mvalue = "TM_mvalue",
  timing = "TM_timing",
  speed = "TM_speed",
  mx1name = "TM_mx1name",
  mx2name = "TM_mx2name",
  mx3name = "TM_mx3name",
  mx1rate = "TM_mx1rate",
  mx2rate = "TM_mx2rate",
  mx3rate = "TM_mx3rate",
  mx1 = "TM_mx1",
  mx2 = "TM_mx2",
  mx3 = "TM_mx3",
  prefixname = "TM_prefixname",
  prefix = "TM_prefix",
  mxstart = "TM_mxstart",
  refresh = "TM_refresh",
  fadeamount = "TM_fadeamount",
  fade = "TM_fade",
  ovrate = "TM_ovrate",
  firststart = "TM_firststart"
}

-- Classes that should have PluginComponent assigned
C.INTERACTIVE_CLASSES = {
  "Button",
  "LineEdit",
  "CheckBox",
}

C.cmdLN = GetDisplayByIndex(1).CmdLineSection
C.screenOV = GetDisplayByIndex(1).ScreenOverlay

-- Debug
function C.echo(message)
  Echo("CONSTANTS READY!")
end

return C
