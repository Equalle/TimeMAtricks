---@diagnostic disable: redundant-parameter
local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

-- PLUGIN STATE
local pluginAlive = nil
local pluginRunning = false
local pluginError = nil

-- CONSTANTS
local PLUGIN_NAME = 'TimeMAtricks'
local PLUGIN_VERSION = 'BETA 0.9.4'
local UI_CMD_ICON_NAME = PLUGIN_NAME .. 'Icon'
local UI_MENU_NAME = PLUGIN_NAME .. ' Menu'
local UI_SETTINGS_NAME = 'Settings Menu'

-- HELPER FUNCTIONS - Global Variables
local function get_global(varName, default)
  return GetVar(GlobalVars(), varName) or default
end

local function set_global(varName, value)
  SetVar(GlobalVars(), varName, value)
  return value ~= nil
end

-- CONSTANTS - UI Colors, Icons, Corners
local colors = {
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
local icons = {
  matricks = 'object_matricks',
  star = 'star',
  cross = 'close',
}
local corners = {
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

-- HELPER FUNCTIONS - Text & Utilities
local function sanitize_text(text)
  text = tostring(text or "")
  if text == "" then return "" end
  -- convert comma to dots
  text = text:gsub(",", ".")
  -- keep only digits and dot
  text = text:gsub("[^%d%.]", "")
  --keep just the first dot
  local fistDotSeen = false
  local cleaned = {}
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "." then
      if not fistDotSeen then
        table.insert(cleaned, c)
        fistDotSeen = true
      end
    else
      table.insert(cleaned, c)
    end
  end
  text = table.concat(cleaned)

  --msut start with a digit, find first digit
  local firstDigit = text:match("%d")
  if not firstDigit then
    return ""
  end

  -- build result
  local digitIndex = text:find(firstDigit, 1, true)
  local afterFirst = text:sub(digitIndex + 1)

  -- ignore any further digits before a possible dot
  local dotPos = afterFirst:find("%.")
  if dotPos then
    --there is a dot after the leading digit
    local decimals = afterFirst:sub(dotPos + 1)
    decimals = decimals:gsub("%.", "")              -- remove any further dots
    decimals = decimals:gsub("[^%d]", ""):sub(1, 2) -- keep only digits, max 2
    if decimals == "" and text:sub(-1) == "." then
      -- user just typed the dot; allow transient
      return firstDigit .. "."
    end
    return firstDigit .. "." .. decimals
  else
    -- no dot, just return leading digits
    return firstDigit
  end
end

-- UI STATE MANAGEMENT
-- Unified save function for both UI and settings state
local function save_state()
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  -- Save UI fields
  local ui_fields = {
    "MasterValue", "Matricks1Value", "Matricks1Rate",
    "Matricks2Value", "Matricks2Rate", "Matricks3Value", "Matricks3Rate",
    "MatricksPrefixValue", "OverallScaleValue"
  }

  for _, name in ipairs(ui_fields) do
    local el = ov:FindRecursive(name)
    if el then
      if name == "OverallScaleValue" then
        set_global("TM_" .. name, el.Text or "")
      else
        set_global("TM_" .. name, el.Content or "")
      end
    end
  end

  -- Save timing / speed master
  local timing = ov:FindRecursive("TimingMaster")
  local speed  = ov:FindRecursive("SpeedMaster")
  if timing then set_global("TM_TimingMaster", timing.State or 1) end
  if speed then set_global("TM_SpeedMaster", speed.State or 0) end

  -- Save matricks buttons
  local matricks_buttons = {
    "Matricks1Button", "Matricks2Button", "Matricks3Button", "MatricksPrefixButton"
  }
  for _, name in ipairs(matricks_buttons) do
    local el = ov:FindRecursive(name)
    if el then set_global("TM_" .. name, el.State or 0) end
  end

  local fade = {
    "FadeAmount"
  }

  for _, name in ipairs(fade) do
    local el = ov:FindRecursive(name)
    if el then
      local size = el[2][1]:Get("Size")
      -- Save fade button text and font
      local fadeLess = ov:FindRecursive("FadeLess")
      local fadeMore = ov:FindRecursive("FadeMore")
      if fadeLess then
        local txt = fadeLess:Get("Text")
        local font = fadeLess:Get("Font", Enums.Roles.Default)
        local enabled = fadeLess:Get("Enabled", Enums.Roles.Default)
        set_global("TM_FadeLessText", txt)
        set_global("TM_FadeLessFont", font)
        set_global("TM_FadeToggle", (enabled == "Yes") and "1" or "0")
      end
      if fadeMore then
        local txt = fadeMore:Get("Text")
        local font = fadeMore:Get("Font", Enums.Roles.Default)
        set_global("TM_FadeMoreText", txt)
        set_global("TM_FadeMoreFont", font)
        if size then
          local normalized = (size - 200) / 300                          -- converts 200-500 range to 0-1
          set_global("TM_FadeValue", tostring(0.3 + (normalized * 0.4))) -- maps to 0.3-0.7
        end
      end
    end
  end

  -- Save settings fields
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_SETTINGS_NAME)
  if ov then
    local matricks_start = ov:FindRecursive("MatricksStartIndex")
    Printf(tostring(matricks_start))
    if matricks_start then
      set_global("TM_MatricksStartIndex", matricks_start.Content or "")
    end

    local refresh_rate = ov:FindRecursive("RefreshRateValue")
    if refresh_rate then
      set_global("TM_RefreshRateValue", refresh_rate.Content or "1")
    end
  end
end

-- Unified load function for both UI and settings state
local function load_state(overlay)
  -- Load plugin state (on/off)
  local on  = overlay:FindRecursive("PluginOn")
  local off = overlay:FindRecursive("PluginOff")
  if on and off then
    if pluginRunning then
      signalTable.plugin_on(on)
    else
      signalTable.plugin_off(off)
    end
  end

  -- Load UI fields
  local ui_fields = {
    "MasterValue",
    "Matricks1Value", "Matricks1Rate",
    "Matricks2Value", "Matricks2Rate",
    "Matricks3Value", "Matricks3Rate",
    "MatricksPrefixValue", "OverallScaleValue",
    "MatricksStartIndex", "RefreshRateValue"
  }

  for _, name in ipairs(ui_fields) do
    local el = overlay:FindRecursive(name)
    if el then
      if name == "OverallScaleValue" then
        local stored = get_global("TM_" .. name, el.Text or "")
        el.Text = stored
      else
        local stored = get_global("TM_" .. name, el.Content or "")
        el.Content = stored
      end
    end
  end

  -- Load timing / speed master
  local timing = overlay:FindRecursive("TimingMaster")
  local speed  = overlay:FindRecursive("SpeedMaster")
  if timing then timing.State = tonumber(get_global("TM_TimingMaster", timing.State or 1)) end
  if speed then speed.State = tonumber(get_global("TM_SpeedMaster", speed.State or 0)) end

  -- Load matricks buttons and enable/disable related fields
  local matricks_mapping = {
    Matricks1Button = { "Matricks1Value", "Matricks1Rate" },
    Matricks2Button = { "Matricks2Value", "Matricks2Rate" },
    Matricks3Button = { "Matricks3Value", "Matricks3Rate" },
    MatricksPrefixButton = { "MatricksPrefixValue" },
  }
  for btn, related in pairs(matricks_mapping) do
    local b = overlay:FindRecursive(btn)
    if b then
      local saved = tonumber(get_global("TM_" .. btn, b.State or 0))
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
    matricks_start.Content = get_global("TM_MatricksStartIndex", matricks_start.Content or "1")
  end

  local refresh_rate = overlay:FindRecursive("RefreshRateValue")
  if refresh_rate then
    refresh_rate.Content = get_global("TM_RefreshRateValue", refresh_rate.Content or "1")
  end

  local fade_amount = overlay:FindRecursive("FadeAmount")
  if fade_amount then
    local stored = tonumber(get_global("TM_FadeValue", "0.5")) or 0.5
    local size = 200 + ((stored - 0.3) / 0.4 * 300)       -- maps 0.3-0.7 to 200-500 range
    fade_amount[2][1]:Set("Size", math.floor(size + 0.5)) -- round to nearest integer
  end

  -- Load fade button text and font
  local fadeLess = overlay:FindRecursive("FadeLess")
  local fadeMore = overlay:FindRecursive("FadeMore")
  if fadeLess then
    fadeLess.Text = get_global("TM_FadeLessText")
    fadeLess.Font = get_global("TM_FadeLessFont")
    fadeLess.Enabled = (get_global("TM_FadeToggle", "1") == "1") and "Yes" or "No"
  end
  if fadeMore then
    fadeMore.Text = get_global("TM_FadeMoreText")
    fadeMore.Font = get_global("TM_FadeMoreFont")
  end
end


-- HELPER FUNCTIONS - MA Version & UI Utilities
local function get_ma_version()
  local text, major, minor, streaming, ui = Version()
  return text, major, minor, streaming, ui
end

local function get_subdir(subdir)
  return (subdir == "CmdLineSection" and GetDisplayByIndex(1).CmdLineSection)
      or (subdir == "ScreenOverlay" and GetDisplayByIndex(1).ScreenOverlay)
end

local function is_valid_ui_item(objname, subdir)
  local dir = get_subdir(subdir)
  if not dir then
    ErrPrintf("subdir not recognized: %s", tostring(subdir))
    return false
  end
  local found = dir:FindRecursive(objname)
  return found ~= nil
end

local function get_ui_item_index(objname, subdir)
  local dir = get_subdir(subdir)
  if not dir then return false end
  for i = 1, dir:Count() do
    if dir:Ptr(i).Name == objname then
      return i
    end
  end
  return false
end

-- Helper to write a text file (overwrites only if content differs)
local function write_text_file(path, content)
  local old = ""
  local f = io.open(path, "rb")
  if f then
    old = f:read("*a") or ""; f:close()
  end
  if old == content then return true end
  local wf, err = io.open(path, "wb")
  if not wf then
    ErrPrintf("Failed to write %s: %s", tostring(path), tostring(err))
    return false
  end
  wf:write(content)
  wf:close()
  return true
end

local UI_XML_CONTENT = [[
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="0.9.0.1">
	<BaseInput Name="TimeMAtricks Menu" H="0" W="700" AlignmentH="Center" AlignmentV="Center" Focus="InitialFocus" CanCoexistWithModal="Yes" BlockClickThru="Yes" SuppressOverlayAutoClose="Yes" HideFocusFrame="Yes" CloseOnEscape="Yes">
		<TitleBar Name="TitleBar" Anchors="0,0" HideFocusFrame="Yes">
			<ItemCollectRows>
				<Item SizePolicy="Fixed" Size="50" />
			</ItemCollectRows>
			<ItemCollectColumns>
				<Item SizePolicy="Stretch" />
				<Item SizePolicy="Fixed" Size="60" />
				<Item SizePolicy="Fixed" Size="50" />
			</ItemCollectColumns>
			<TitleButton Name="TitleButton" Text="" Anchors="0,0" Texture="corner1" Icon="object_matricks" IconColor="Button.Icon" />
			<Button Name="SettingsBtn" Tooltip="Open the Timematricks Settings" Anchors="1,0" Texture="corner0" Clicked=":open_settings" Icon="hardkey_setup" Focus="WantsFocus" />
			<CloseButton Name="CloseBtn" Tooltip="Close the Timematricks Settings" Anchors="2,0" Texture="corner2" />
			<WarningInfoButton Name="WarningButton" Anchors="0,0,2,0" Font="Regular32" BackColor="Global.AlertText" />
		</TitleBar>

		<!-- Main Content -->
		<DialogFrame Name="MainContent" Anchors="0,1" Padding="2,4,2,4" CanCoexistWithModal="Yes" HideFocusFrame="Yes">
			<ItemCollectRows>
				<Item SizePolicy="Fixed" Size="30" />
				<!-- Version -->
				<Item SizePolicy="Stretch" />
				<!-- Plugin Buttons -->
				<Item SizePolicy="Fixed" Size="45" />
				<!-- Settings -->
				<Item SizePolicy="Fixed" Size="65" />
				<!-- Master Select -->
				<Item SizePolicy="Fixed" Size="30" />
				<!-- Matricks Titlebar -->
				<Item SizePolicy="Fixed" Size="50" />
				<!-- Matricks 1 -->
				<Item SizePolicy="Fixed" Size="50" />
				<!-- Matricks 2 -->
				<Item SizePolicy="Fixed" Size="50" />
				<!-- Matricks 3 -->
				<Item SizePolicy="Fixed" Size="55" />
				<!-- Matricks Prefix -->
				<Item SizePolicy="Fixed" Size="30" />
				<!-- Fade Titlebar -->
				<Item SizePolicy="Fixed" Size="70" />
				<!-- Fade Amount -->
				<Item SizePolicy="Fixed" Size="60" />
				<!-- Scale Titlebar -->
				<Item SizePolicy="Fixed" Size="100" />
				<!-- Overall Scale -->
				<Item SizePolicy="Fixed" Size="80" />
				<!-- Close -->
			</ItemCollectRows>
			<ItemCollectColumns>
				<Item SizePolicy="Stretch" />
			</ItemCollectColumns>

			<!-- Version -->
			<UILayoutGrid Name="Version Frame" H="100%" W="100%" Anchors="0,0">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="30" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="Version" Text="" Anchors="0,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner15" HasHover="0" Focus="Never" HasPressedAnimation="No" />
			</UILayoutGrid>

			<!-- Plugin Buttons -->
			<UILayoutGrid Name="PluginButtons" H="100%" W="100%" Anchors="0,1" Padding="0,5,0,5">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="80" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="PluginOff" Text="Plugin Off" Tooltip="Turns plugin loop OFF" Anchors="0,0" BackColor="Button.BackgroundClear" Texture="corner5" TextColor="Global.WarningText" Font="Medium20" TextShadow="Yes" Focus="Never" />
				<Button Name="PluginOn" Text="Plugin On" Tooltip="Turns plugin loop ON" Anchors="1,0" BackColor="Button.Background" Texture="corner10" TextColor="Global.Text" Font="Medium20" TextShadow="Yes" Focus="Never" />
			</UILayoutGrid>

			<!-- Settings -->
			<UILayoutGrid Name="Settings" H="100%" W="100%" Anchors="0,2">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="40" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="Settings" Text="Settings" Anchors="0,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner15" HasHover="0" Focus="Never" HasPressedAnimation="No" />
			</UILayoutGrid>

			<!-- Master Select -->
			<UILayoutGrid Name="Master" H="100%" W="100%" Anchors="0,3">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="60" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="334" />
				</ItemCollectColumns>
				<Button Name="TimingMaster" Text="Timing Master" Tooltip="Sets the master to timing" Anchors="0,0" BackColor="Button.Background" Texture="corner5" HasHover="1" Focus="Never" />
				<Button Name="SpeedMaster" Text="Speed Master" Tooltip="Sets the master to speed" Anchors="1,0" BackColor="Button.Background" Texture="corner10" HasHover="1" Focus="Never" />
				<LineEdit Name="MasterValue" Message="Object number" Tooltip="Enter desired master object number you want the plugin to listen to" Anchors="2,0" Padding="0,0,10,0" Icon="master" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner15" KeyboardIconAlignmentH="Left" Focus="InitialFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter="0123456789" OnWrongChar=":ShowWarning" TextChanged=":sanitize" MaxTextLength="2"/>
			</UILayoutGrid>

			<!-- Matricks Titlebar -->
			<UILayoutGrid Name="MatricksTitlebar" H="100%" W="100%" Anchors="0,4">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="30" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="250" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="130" />
				</ItemCollectColumns>
				<Button Name="MatricksSettings" Text="Toggle" Anchors="0,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner1" HasHover="0" Focus="Never" HasPressedAnimation="No" />
				<Button Name="MatricksSettings" Text="Object name" Anchors="1,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner0" HasHover="0" Focus="Never" HasPressedAnimation="No" />
				<Button Name="MatricksSettings" Text="rate" Anchors="2,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner2" HasHover="0" Focus="Never" HasPressedAnimation="No" />
			</UILayoutGrid>

			<!-- Matricks 1 -->
			<UILayoutGrid Name="Matricks1" H="100%" W="100%" Anchors="0,5">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="50" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="250" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="130" />
				</ItemCollectColumns>
				<CheckBox Name="Matricks1Button" Text="MAtricks 1" Tooltip="Toggles MAtricks 1" Anchors="0,0" Texture="corner1" BackColor="Button.Background" HasHover="1" Focus="Never" />
				<LineEdit Name="Matricks1Value" Message="Object name" Tooltip="Enter the name or object number for MAtricks 1" Anchors="1,0" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter=" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZÜÖÄßüöä1234567890!§%/()=?`´°+#'-_:&lt;&gt;«∑€®†Ω¨⁄øπ•å‚∂ƒ©ªº∆@œæ≤¥≈ç√∫µ∞……––‘±¡“¶¢[]≠¿'•‘””#£ﬁ˜·¯˙˚’Æ—÷˛ŒÆ°»„‰¸˝ˇÁÛØ∏ÅÍ™ÏÌÓıˆﬂ‡ÙÇ◊‹›˘" OnWrongChar=":ShowWarning" />
				<LineEdit Name="Matricks1Rate" Message="rate" Tooltip="Enter the rate for MAtricks 1" Anchors="2,0" Padding="0,0,5,0" Icon="object_xkeys" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="CanHaveFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" Filter="0123456789.," TextChanged=":sanitize" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" VKPluginName="TextInputNumOnly" OnWrongChar=":ShowWarning" />
			</UILayoutGrid>

			<!-- Matricks 2 -->
			<UILayoutGrid Name="Matricks2" H="100%" W="100%" Anchors="0,6">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="50" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="250" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="130" />
				</ItemCollectColumns>
				<CheckBox Name="Matricks2Button" Text="MAtricks 2" Tooltip="Toggles MAtricks 2" Anchors="0,0" Texture="corner0" BackColor="Button.Background" HasHover="1" Focus="Never" />
				<LineEdit Name="Matricks2Value" Message="Object name" Tooltip="Enter the name or object number for MAtricks 2" Anchors="1,0" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter=" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZÜÖÄßüöä1234567890!§%/()=?`´°+#'-_:&lt;&gt;«∑€®†Ω¨⁄øπ•å‚∂ƒ©ªº∆@œæ≤¥≈ç√∫µ∞……––‘±¡“¶¢[]≠¿'•‘””#£ﬁ˜·¯˙˚’Æ—÷˛ŒÆ°»„‰¸˝ˇÁÛØ∏ÅÍ™ÏÌÓıˆﬂ‡ÙÇ◊‹›˘" OnWrongChar=":ShowWarning" />
				<LineEdit Name="Matricks2Rate" Message="rate" Tooltip="Enter the rate for MAtricks 2" Anchors="2,0" Padding="0,0,5,0" Icon="object_xkeys" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="CanHaveFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" Filter="0123456789.," TextChanged=":sanitize" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" VKPluginName="TextInputNumOnly" OnWrongChar=":ShowWarning" />
			</UILayoutGrid>

			<!-- Matricks 3 -->
			<UILayoutGrid Name="Matricks3" H="100%" W="100%" Anchors="0,7">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="50" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="250" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="130" />
				</ItemCollectColumns>
				<CheckBox Name="Matricks3Button" Text="MAtricks 3" Tooltip="Toggles MAtricks 3" Anchors="0,0" Texture="corner0" BackColor="Button.Background" HasHover="1" Focus="Never" />
				<LineEdit Name="Matricks3Value" Message="Object name" Tooltip="Enter the name or object number for MAtricks 3" Anchors="1,0" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter=" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZÜÖÄßüöä1234567890!§%/()=?`´°+#'-_:&lt;&gt;«∑€®†Ω¨⁄øπ•å‚∂ƒ©ªº∆@œæ≤¥≈ç√∫µ∞……––‘±¡“¶¢[]≠¿'•‘””#£ﬁ˜·¯˙˚’Æ—÷˛ŒÆ°»„‰¸˝ˇÁÛØ∏ÅÍ™ÏÌÓıˆﬂ‡ÙÇ◊‹›˘" OnWrongChar=":ShowWarning" />
				<LineEdit Name="Matricks3Rate" Message="rate" Tooltip="Enter the rate for MAtricks 3" Anchors="2,0" Padding="0,0,5,0" Icon="object_xkeys" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner0" KeyboardIconAlignmentH="Left" Focus="CanHaveFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" TextChanged=":sanitize" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter="0123456789.," VKPluginName="TextInputNumOnly" OnWrongChar=":ShowWarning" />
			</UILayoutGrid>

			<!-- Matricks Prefix -->
			<UILayoutGrid Name="MatricksPrefix" H="100%" W="100%" Anchors="0,8">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="50" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="250" />
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<CheckBox Name="MatricksPrefixButton" Text="MAtricks Prefix" Tooltip="Toggles MAtricks Prefix" Anchors="0,0" Texture="corner4" BackColor="Button.Background" HasHover="1" Focus="Never" />
				<LineEdit Name="MatricksPrefixValue" Message="Name prefix" Tooltip="Enter the name or object number for MAtricks Prefix" Anchors="1,0" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner8" KeyboardIconAlignmentH="Left" Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect" DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter" Filter=" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZÜÖÄßüöä1234567890!§%/()=?`´°+#'-_:&lt;&gt;«∑€®†Ω¨⁄øπ•å‚∂ƒ©ªº∆@œæ≤¥≈ç√∫µ∞……––‘±¡“¶¢[]≠¿'•‘””#£ﬁ˜·¯˙˚’Æ—÷˛ŒÆ°»„‰¸˝ˇÁÛØ∏ÅÍ™ÏÌÓıˆﬂ‡ÙÇ◊‹›˘" OnWrongChar=":ShowWarning" />
			</UILayoutGrid>

			<!-- Fade Titlebar -->
			<UILayoutGrid Name="FadeTitlebar" H="100%" W="100%" Anchors="0,9">
				<ItemCollectRows>
					<Item SizePolicy="Stretch" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="FadeTitle" Text="Fade Amount (Hold to Toggle)" Anchors="0,0" Margin="0,0,0,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner3" HasHover="0" Focus="Never" HasPressedAnimation="No" />
			</UILayoutGrid>

			<!-- Fade Amount -->
			<UILayoutGrid Name="FadeAmount" H="100%" W="100%" Anchors="0,10">
				<ItemCollectRows>
					<Item SizePolicy="Stretch" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="350"/>
					<Item SizePolicy="Stretch"/>
				</ItemCollectColumns>
				<Button Name="FadeLess" Text="Fade Less" TextShadow="Yes" Tooltip="Decreases the fade amount" Anchors="0,0" Texture="corner4" HasHover="1" Focus="Never" Clicked="fade_adjust" />
				<WarningInfoButton Name="FadeLessWarning" Anchors="0,0,1,0" Texture="corner15" HasHover="1" Focus="Never" BackColor="Global.ErrorText"/>
				<Button Name="FadeMore" Text="Fade More" TextShadow="Yes" Tooltip="Increases the fade amount" Anchors="1,0" Texture="corner8" HasHover="1" Focus="Never" Clicked="fade_adjust" />
				<WarningInfoButton Name="FadeMoreWarning" Anchors="1,0,1,0" HasHover="1" Focus="Never" BackColor="Global.ErrorText"/>
			</UILayoutGrid>

			<!-- Scale Titlebar -->
			<UILayoutGrid Name="ScaleTitlebar" H="100%" W="100%" Anchors="0,11">
				<ItemCollectRows>
					<Item SizePolicy="Stretch" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="ScaleSettings" Text="Overall Scale" Anchors="0,0" Margin="0,5,0,0" BackColor="CheckBox.ReadOnlyBackground" Texture="corner3" HasHover="0" Focus="Never" HasPressedAnimation="No" />
			</UILayoutGrid>

			<!-- Overall Scale -->
			<UILayoutGrid Name="OverallScale" H="100%" W="100%" Anchors="0,12">
				<ItemCollectRows>
					<Item SizePolicy="Stretch" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Fixed" Size="200" />
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Fixed" Size="200" />
				</ItemCollectColumns>
				<Button Name="HT" Tooltip="Sets all MAtricks rates to half the current rate" Anchors="0,0" Icon="ExecuteHalfSpeed84" Padding="25,10,25,10" BackColor="Button.Background" Texture="corner4" HasHover="1" Focus="Never" />
				<Button Name="OverallScaleValue" Text="1" TextAlignmentV="Top" Tooltip="Shows the current rate" Anchors="1,0" Padding="0,20,0,0" Icon="" IconAlignmentH="Center" IconAlignmentV="Top" BackColor="CheckBox.ReadOnlyBackground" TextColor="CheckBox.ReadOnlyText" Font="Regular28" Texture="corner0" TextShadow="Yes" Focus="Never" HasHover="0" HasPressedAnimation="No" />
				<Button Name="DT" Tooltip="Sets all MAtricks rates to double the current rate" Anchors="2,0" Icon="ExecuteDoubleSpeed84" Padding="25,10,25,10" BackColor="Button.Background" Texture="corner8" HasHover="1" Focus="Never" />
				<Button Name="ResetRate" Tooltip="Resets rate to 1" Anchors="1,0" H="35" Margin="35,65,35,0" Icon="ExecuteRate120" IconAlignmentH="Center" BackColor="Button.Background" Texture="corner15" HasHover="1" Focus="Never" />
			</UILayoutGrid>

			<!-- Close -->
			<UILayoutGrid Name="CloseButton" H="100%" W="100%" Anchors="0,13" Padding="0,5,0,0">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="80" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
					<!-- <Item SizePolicy="Stretch" /> -->
				</ItemCollectColumns>
				<Button Name="Apply" Text="Apply" Tooltip="Apply settings (autosave on close)" Anchors="0,0" Margin="0,0,0,5" BackColor="Button.Background" Texture="corner15" Focus="Never" KeyDown=":ExecuteOnEnter" HideFocusFrame="No" />
				<!-- <Button Name="Close" Text="Close" Tooltip="Close the Timematricks Settings" Anchors="1,0" Margin="0,0,0,5" BackColor="Button.Background" Texture="corner10" Focus="WantsFocus" KeyDown=":ExecuteOnEnter" HideFocusFrame="No" /> -->
				<WarningInfoButton Name="WarningButton2" Anchors="0,0,0,0" Font="Regular32" BackColor="Global.SelectedInverted" Texture="corner15"/>
			</UILayoutGrid>
		</DialogFrame>
	</BaseInput>
</GMA3>
]]

local UI_XML_SETTINGS = [[
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="0.9.0.1">
	<BaseInput Name="Settings Menu" H="0" W="700" AlignmentH="Center" AlignmentV="Center"
		Focus="InitialFocus" CanCoexistWithModal="Yes" BlockClickThru="Yes"
		SuppressOverlayAutoClose="Yes" HideFocusFrame="Yes" CloseOnEscape="Yes">
		<TitleBar Name="TitleBar" Anchors="0,0" HideFocusFrame="Yes">
			<ItemCollectRows>
				<Item SizePolicy="Fixed" Size="50" />
			</ItemCollectRows>
			<ItemCollectColumns>
				<Item SizePolicy="Stretch" />
				<Item SizePolicy="Fixed" Size="50" />
			</ItemCollectColumns>
			<TitleButton Name="TitleButton" Text="TimeMAtricks Settings" Anchors="0,0" Texture="corner1"
				Icon="object_matricks" IconColor="Button.Icon" />
			<CloseButton Name="CloseBtn" Tooltip="Close the Timematricks Settings" Anchors="1,0"
				Texture="corner2" Icon="close"/>
			<WarningInfoButton Name="WarningButton" Anchors="0,0,1,0" Font="Regular32"
				BackColor="Global.AlertText" />
		</TitleBar>

		<!-- Main Content -->
		<DialogFrame Name="Content" Anchors="0,1" Padding="2,4,2,4" CanCoexistWithModal="Yes"
			HideFocusFrame="Yes">
			<ItemCollectRows>
                <Item SizePolicy="Fixed" Size="100"/>
                <Item SizePolicy="Fixed" Size="80"/>
			</ItemCollectRows>
			<ItemCollectColumns>
				<Item SizePolicy="Stretch" />
			</ItemCollectColumns>

			<!-- Matricks Prefix -->
			<UILayoutGrid Name="MatricksPrefix" H="100%" W="100%" Anchors="0,0">
				<ItemCollectRows>
						<Item SizePolicy="Fixed" Size="50" />
						<Item SizePolicy="Fixed" Size="50" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
					<Button Name="MatricksStartHandle" Text="Matricks Pool Start" Anchors="0,0" TextAlignmentH="Center" TextAlignmentV="Center" HasHover="No" Focus="Never"/>
					<LineEdit Name="MatricksStartIndex" Message="Pool number (should be free)"
						Tooltip="Enter pool number to start at" Anchors="1,0"
						Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right"
						IconAlignmentV="Center" Texture="corner10" KeyboardIconAlignmentH="Left"
						Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect"
						DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter"
						Filter="1234567890" VKPluginName="TextInputNumOnly" MaxTextLength="4"
						OnWrongChar=":ShowWarning"/>

					<!-- Refresh Rate Row -->
					<Button Name="RefreshRateLabel" Text="Refresh Rate (s)" Anchors="0,1" TextAlignmentH="Center" TextAlignmentV="Center" HasHover="No"
						Focus="Never"/>
					<LineEdit Name="RefreshRateValue" Message="Enter refresh rate in s"
						Tooltip="Enter refresh rate in seconds" Anchors="1,1"
						Padding="0,0,10,0" Icon="rotate" IconAlignmentH="Right"
						IconAlignmentV="Center" Texture="corner10" KeyboardIconAlignmentH="Left"
						Focus="WantsFocus" FocusGet=":LineEditSelectAll" FocusLost=":LineEditDeSelect"
						DoubleClicked=":LineEditSelectAll" KeyDown=":ExecuteOnEnter"
						Filter="1234567890." TextChanged=":sanitize" VKPluginName="TextInputNumOnly"
						OnWrongChar=":ShowWarning"/>
			</UILayoutGrid>

			<!-- Close -->
			<UILayoutGrid Name="CloseButton" H="100%" W="100%" Anchors="0,1" Padding="0,5,0,0">
				<ItemCollectRows>
					<Item SizePolicy="Fixed" Size="80" />
				</ItemCollectRows>
				<ItemCollectColumns>
					<Item SizePolicy="Stretch" />
					<Item SizePolicy="Stretch" />
				</ItemCollectColumns>
				<Button Name="Apply" Text="Apply" Tooltip="Apply settings (autosave on close)"
					Anchors="0,0" Margin="0,0,0,5" BackColor="Button.Background" Texture="corner5"
					Focus="WantsFocus" KeyDown=":ExecuteOnEnter" HideFocusFrame="No" Focus="Never"/>
				<Button Name="Close" Text="Close" Tooltip="Close the Timematricks Settings"
					Anchors="1,0" Margin="0,0,0,5" BackColor="Button.Background" Texture="corner10"
					Focus="WantsFocus" KeyDown=":ExecuteOnEnter" HideFocusFrame="No" Focus="Never"/>
				<WarningInfoButton Name="WarningButton2" Anchors="0,0,0,0" Font="Regular32"
					BackColor="Global.SelectedInverted" />
			</UILayoutGrid>
		</DialogFrame>
	</BaseInput>
</GMA3>
]]


-- XML MANAGEMENT
-- Generic function to resolve XML files
-- xmlType: "ui" or "settings"
local function resolve_xml_file(xmlType)
  local base = GetPath("temp") or ""
  -- local base = '/Users/juriseiffert/Documents/GrandMA3 Plugins/TimeMAtricks'
  -- local base = 'C:\\Users\\Juri\\iCloudDrive\\Lua Plugins\\GMA3\\TimeMAtricks'
  local dir = base .. "/"
  local filename, content

  if xmlType == "ui" then
    filename = "TimeMAtricks_UI.xml"
    content = UI_XML_CONTENT
  elseif xmlType == "settings" then
    filename = "TimeMAtricks_Settings_UI.xml"
    content = UI_XML_SETTINGS
  else
    ErrPrintf("Unknown XML type: %s", tostring(xmlType))
    return nil, nil
  end

  local slash = "/"
  local full = dir .. slash .. filename
  if not FileExists(full) then
    local ok = write_text_file(full, content)
    if not ok then
      full = (base .. "/" .. filename)
      write_text_file(full, content)
      dir = base
    end
  end

  -- ui:Import needs directory (with trailing sep) and filename
  local dirWithSep = dir:match("^(.*[/\\])$") and dir or (dir .. "/")
  return dirWithSep, filename
end

-- MATH FUNCTIONS
function BPM_quartic(normed)
  -- coefficients (highest -> lowest): a4,a3,a2,a1,a0
  local a4 = 1.4782363954528236e-07
  local a3 = -4.7011506911898910e-05
  local a2 = 0.02546732094127444
  local a1 = 0.02565532641182032
  local a0 = -0.015923207227581285
  local y = ((((a4 * normed + a3) * normed + a2) * normed + a1) * normed + a0)
  if y <= 30 then y = 30 end
  if y >= 0 then
    return math.floor(y * 10 + 0.5) / 10
  else
    return math.ceil(y * 10 - 0.5) / 10
  end
end

-- FADE ADJUSTMENT
local function fade_adjust(direction, caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local sl = ov:FindRecursive("FadeAmount")
  local less = ov:FindRecursive("FadeLess")
  local more = ov:FindRecursive("FadeMore")
  local wmore = ov:FindRecursive("FadeMoreWarning")
  local wless = ov:FindRecursive("FadeLessWarning")
  if sl then
    local cur = tonumber(sl[2][1]:Get("Size"))
    local min, max, step = 200, 500, 60
    local new = cur + (step * direction)
    if new >= min and new <= max then
      sl[2][1]:Set("Size", new)
      local chcur = tonumber(sl[2][1]:Get("Size"))
      local old = tonumber(get_global("TM_FadeValue", 0.5)) or 0.5
      local delta = 0.1 * direction
      local updated = old + delta
      if (direction == -1 and chcur >= 200) or (direction == 1 and chcur <= 500) then
        set_global("TM_FadeValue", tostring(updated))
      end
      if caller.Name == "FadeLess" and tonumber(chcur) == 230 then
        less.Text = "MIN"
        less.Font = "Medium20"
        more.Text = "Fade More"
        more.Font = "Regular18"
        wless.ShowAnimation()
      elseif caller.Name == "FadeMore" and tonumber(chcur) == 470 then
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


-- UI ELEMENT CONFIGURATION
-- Generic function to configure UI elements
-- elementType: "button", "checkbox", "textbox", "hold"
local function add_ui_element(name, overlay, elementType, options)
  local el = overlay:FindRecursive(name)
  if not el then
    local typeDesc = elementType == "checkbox" and "Box" or
        elementType == "textbox" and "Textbox" or "Button"
    ErrPrintf("%s not found: %s", typeDesc, tostring(name))
    return false
  end

  el.PluginComponent = myHandle

  -- Handle different element types
  if elementType == "button" or elementType == "checkbox" then
    el.Clicked = options.clicked or ""
  end

  if elementType == "hold" then
    el.MouseDownHold = options.hold or ""
  end

  if elementType == "checkbox" and options.state ~= nil then
    el.State = options.state
  end

  if elementType == "textbox" and options.content ~= nil then
    el.Content = options.content
  end

  if options.enabled ~= nil then
    el.Enabled = options.enabled
  else
    el.Enabled = "Yes"
  end

  return true
end


-- UI CREATION FUNCTIONS
local function create_menu()
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  local ui = overlay:Append('BaseInput')
  ui.SuppressOverlayAutoclose = "Yes"
  ui.AutoClose = "No"
  ui.CloseOnEscape = "Yes"

  local path, filename = resolve_xml_file("ui")
  Echo("Import from " .. tostring(path) .. tostring(filename))
  if not path then
    ErrPrintf("UI XML file not found")
    return
  end

  if not ui:Import(path, filename) then
    ErrPrintf("Failed to import UI XML from %s%s", tostring(path), tostring(filename))
    return
  end

  ui:HookDelete(signalTable.close, ui)

  -- wire up and set initial defaults first
  local buttons = {
    -- { "CloseBtn",    "close" },
    { "SettingsBtn", "open_settings" },
    { "PluginOff",   "plugin_off" },
    { "PluginOn",    "plugin_on" },
    { "FadeLess",    "fade_adjust" },
    { "FadeMore",    "fade_adjust" },
    -- { "Close",       "close" },
    { "Apply",       "apply" },
  }
  for _, b in ipairs(buttons) do
    if not add_ui_element(b[1], ui, "button", { clicked = b[2] }) then
      ErrPrintf("error at %s", b)
    end
  end

  local holds = {
    { "FadeLess", "fade_hold" },
    { "FadeMore", "fade_hold" },
  }
  for _, h in ipairs(holds) do
    if not add_ui_element(h[1], ui, "hold", { hold = h[2] }) then
      ErrPrintf("error at %s", h)
    end
  end

  local checks = {
    { "TimingMaster",         "master_swap",     1 },
    { "SpeedMaster",          "master_swap",     0 },
    { "Matricks1Button",      "matricks_toggle", 1 },
    { "Matricks2Button",      "matricks_toggle", 0 },
    { "Matricks3Button",      "matricks_toggle", 0 },
    { "MatricksPrefixButton", "matricks_toggle", 0 },
  }
  for _, c in ipairs(checks) do
    if not add_ui_element(c[1], ui, "checkbox", { clicked = c[2], state = c[3] }) then
      ErrPrintf("error at %s", c)
    end
  end

  local texts = {
    { "MasterValue",    "text" }, -- no default -> keep existing
    { "Matricks1Value", "text" }, { "Matricks1Rate", "text", "0.25" },
    { "Matricks2Value", "text" }, { "Matricks2Rate", "text", "0.5" },
    { "Matricks3Value", "text" }, { "Matricks3Rate", "text", "1" },
    { "MatricksPrefixValue", "text" },
    --{ "RefreshRateValue",    "text", "1.5" },
  }
  for _, t in ipairs(texts) do
    if not add_ui_element(t[1], ui, "textbox", { content = t[3] }) then
      ErrPrintf("error at %s", t)
    end
  end

  local rates = {
    { "HT",        "rate_mod",          1 },
    { "ResetRate", "reset_overallrate", 1 },
    { "DT",        "rate_mod",          1 },
  }

  for _, r in ipairs(rates) do
    if not add_ui_element(r[1], ui, "button", { clicked = r[2] }) then
      ErrPrintf("error at %s", r)
    end
  end

  local plugininfo = {
    { "TitleButton", PLUGIN_NAME,                 icons.matricks },
    { "Version",     "Version " .. PLUGIN_VERSION },
  }

  for _, p in ipairs(plugininfo) do
    local el = ui:FindRecursive(p[1])
    if el then
      el.Text = p[2] or ""
      if p[3] then
        el.Icon = p[3]
      end
    end
  end

  -- now load saved globals so they override the defaults set above
  load_state(ui)
  save_state()
  coroutine.yield(0.1) -- slight delay to ensure UI is ready
  if overlay:FindRecursive("MasterValue").Content == "" then
    FindBestFocus(ui:FindRecursive("MasterValue"))
  else
    FindBestFocus(ui:FindRecursive("Matricks1Value"))
  end


  local less = ui:FindRecursive("FadeLess")
  less.BackColor = colors.background.fade

  local more = ui:FindRecursive("FadeMore")
  more.BackColor = colors.background.delay
end

local function create_CMDlineIcon()
  local cmdbar               = GetDisplayByIndex(1).CmdLineSection
  local lastCols             = tonumber(cmdbar:Get("Columns"))
  local cols                 = lastCols + 1
  cmdbar.Columns             = cols
  cmdbar[2][cols].SizePolicy = "Fixed"
  cmdbar[2][cols].Size       = 50

  TMIcon                     = cmdbar:Append('Button')
  TMIcon.Name                = UI_CMD_ICON_NAME
  TMIcon.Anchors             = { left = cols - 2 }
  TMIcon.W                   = 49
  TMIcon.PluginComponent     = myHandle
  TMIcon.Clicked             = 'cmdbar_clicked'
  TMIcon.Icon                = icons.matricks
  TMIcon.IconColor           = colors.icon.inactive
  TMIcon.Tooltip             = "TimeMAtricks Plugin"

  Tri                        = cmdbar:FindRecursive("RightTriangle")
  if Tri then
    Tri.Anchors = { left = cols - 1 }
  end
end

local function delete_CMDlineIcon()
  if TMIcon then
    local cmdbar = GetDisplayByIndex(1).CmdLineSection
    local iconPosition = TMIcon.Anchors.left or 0 -- Get the actual position

    -- Remove the icon
    cmdbar:Remove(TMIcon:Get("No"))
    TMIcon = nil

    -- Decrease column count
    local currentCols = tonumber(cmdbar:Get("Columns"))
    cmdbar.Columns = currentCols - 1

    -- Shift all items that were to the right of the removed icon
    for i = 1, cmdbar:Count() do
      local item = cmdbar:Ptr(i)
      if item and item.Anchors and item.Anchors.left then
        local itemPosition = item.Anchors.left
        if itemPosition > iconPosition then
          item.Anchors = { left = itemPosition - 1 }
        end
      end
    end

    -- The triangle should now be at the last position
    local Tri = cmdbar:FindRecursive("RightTriangle")
    if Tri then
      Tri.Anchors = { left = currentCols - 2 } -- New last column (0-based)
    end
  end
end

local function create_panic_macro()
  local macroPool = DataPool(1).Macros
  local freeIndex = nil

  -- Find first free macro slot
  local macros = DataPool(1).Macros
  local newMacro = macros:Acquire()

  if not newMacro then
    ErrPrintf("No free macro slot found")
    return false
  end

  -- Create new macro
  if not newMacro then
    ErrPrintf("Failed to create panic macro")
    return false
  end

  newMacro:Set("Name", "TimeMAtricks Reset")
  newMacro:Set("Note", "Deletes all TimeMAtricks global variables")

  -- Add delete commands for all global variables
  local globalVars = {
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

  for i, varName in ipairs(globalVars) do
    local line = newMacro:Append()
    if line then
      line:Set("Command", 'DeleteGlobalVariable "' .. varName .. '"')
    end
  end
  Printf("Created 'TimeMAtricks Reset' Macro")
  Printf("Use to reset all TimeMAtricks settings")
  return true
end

-- MATRICKS HANDLING

-- Collect all matricks from the pool
local function get_all_matricks()
  local mxpath = DataPool(1).Matricks
  local mxt = {}
  for i = 1, 10000 do
    local p = mxpath:Ptr(i)
    if p then
      mxt[i] = {
        index = i,
        note = p:Get("Note"),
        name = p:Get("Name")
      }
    end
  end
  return mxt, mxpath
end

-- Handle prefix value changes
local function handle_prefix_change(caller, oldPrefix, newPrefix)
  if newPrefix == "" then
    signalTable.ShowWarning(caller, "Prefix can not be empty")
    caller:Set("Content", oldPrefix)
    save_state()
    return
  end

  local mxt, mxpath = get_all_matricks()
  for i, v in ipairs(mxt) do
    local name = v.name
    if name and name ~= "" then
      local obj = mxpath:FindRecursive(name)
      if obj then
        -- Remove old prefix if present
        local strippedName = name
        if strippedName:sub(1, #oldPrefix) == oldPrefix then
          strippedName = strippedName:sub(#oldPrefix + 1)
        end
        obj:Set("Name", newPrefix .. strippedName)
      end
    end
  end
  save_state()
end

-- Validate matricks name
local function validate_matricks_name(caller, callerid, content)
  local globals = {
    get_global("TM_Matricks1Value"),
    get_global("TM_Matricks2Value"),
    get_global("TM_Matricks3Value"),
  }

  -- Check for duplicate names
  for i, v in ipairs(globals) do
    if i ~= callerid and content == globals[i] then
      signalTable.ShowWarning(caller, "Name already used")
      local oldValue = get_global("TM_Matricks" .. callerid .. "Value", "")
      caller:Set("Content", oldValue)
      save_state()
      return false
    end
  end

  -- Check for empty name
  if content == "" then
    signalTable.ShowWarning(caller, "Matricks name can not be empty")
    local oldValue = get_global("TM_Matricks" .. callerid .. "Value", "")
    caller:Set("Content", oldValue)
    save_state()
    return false
  end

  return true
end

-- Rename existing matricks triplet
local function rename_matricks_triplet(callerid, newName, prefix, mxt, mxpath)
  local cand = {}

  -- Find existing matricks with correct notes
  for _, v in pairs(mxt) do
    for i = 1, 3 do
      if v.note == "TimeMatricks " .. callerid .. "." .. i then
        cand[i] = {
          index = v.index,
          name = v.name
        }
      end
    end
  end

  -- Rename all three matricks
  for i = 1, 3 do
    local found = false
    -- Try to find in candidates first
    if cand[i] and cand[i].name ~= newName then
      local obj = mxpath:FindRecursive(cand[i].name)
      if obj then
        obj:Set("Name", tostring(prefix .. newName .. " " .. i))
        found = true
      end
    end
    -- If not found in candidates, search all matricks
    if not found then
      for _, v in pairs(mxt) do
        if v.note == ("TimeMatricks " .. callerid .. "." .. i) then
          local obj = mxpath:FindRecursive(v.name)
          if obj and v.name ~= newName then
            obj:Set("Name", tostring(prefix .. newName .. " " .. i))
          end
        end
      end
    end
  end
end

-- Create new matricks triplet
local function create_matricks_triplet(callerid, newName, prefix, mxt, mxpath)
  for i = 1, 3 do
    local exists = false
    local targetName = tostring(prefix .. newName .. " " .. i)
    local targetNote = "TimeMatricks " .. callerid .. "." .. i

    -- Check if already exists
    for _, v in pairs(mxt) do
      local obj = mxpath:FindRecursive(v.name)
      local objname = obj and obj:Get("Name") or ""
      local objnote = obj and obj:Get("Note") or ""
      if objname == targetName or objnote == targetNote then
        exists = true
        break
      end
    end

    if not exists then
      -- Find first free slot
      local startidx = tonumber(get_global("TM_MatricksStartIndex", "1")) or 1
      local freeidx = nil
      for n = startidx, 10000 do
        if not mxpath:Ptr(n) then
          freeidx = n
          break
        end
      end

      if not freeidx then
        return false, "No free Matricks slot found"
      end

      local newobj = mxpath:Create(freeidx)
      if not newobj then
        return false, "Failed to create new object"
      end

      newobj:Set("Name", prefix .. newName .. " " .. i)
      newobj:Set("Note", targetNote)
      newobj:Set("InvertStyle", "All")
    end
  end
  return true
end

-- Handle matricks value changes
local function handle_matricks_value_change(caller)
  local callerid
  if caller.Name == "Matricks1Value" then
    callerid = 1
  elseif caller.Name == "Matricks2Value" then
    callerid = 2
  elseif caller.Name == "Matricks3Value" then
    callerid = 3
  else
    return
  end

  local content = caller.Content or ""

  -- Validate the name
  if not validate_matricks_name(caller, callerid, content) then
    return
  end

  -- Get prefix
  local prefixToggle = (tonumber(get_global("TM_MatricksPrefixButton", 0)) or 1)
  local oldPrefix = get_global("TM_MatricksPrefixValue", "") or ""
  local prefix = ""
  if prefixToggle == 1 and oldPrefix ~= "" then
    prefix = tostring(oldPrefix)
  end

  -- Get all matricks
  local mxt, mxpath = get_all_matricks()

  -- Check if triplet exists
  local found_any = false
  for _, v in pairs(mxt) do
    for i = 1, 3 do
      if v.note == "TimeMatricks " .. callerid .. "." .. i then
        found_any = true
        break
      end
    end
    if found_any then break end
  end

  if found_any then
    -- Rename existing triplet
    rename_matricks_triplet(callerid, content, prefix, mxt, mxpath)
  else
    -- Create new triplet
    local success, error = create_matricks_triplet(callerid, content, prefix, mxt, mxpath)
    if not success then
      signalTable.ShowWarning(caller, error)
      return
    end
  end

  save_state()
end

-- Main matricks handler
local function matricks_handler(caller)
  if not caller then return end
  local cname = caller.Name or ""

  local prefixToggle = (tonumber(get_global("TM_MatricksPrefixButton", 0)) or 1)
  local oldPrefix = get_global("TM_MatricksPrefixValue", "") or ""

  if cname == "MatricksPrefixValue" then
    local newPrefix = caller.Content or ""
    if prefixToggle == 1 and newPrefix ~= oldPrefix then
      handle_prefix_change(caller, oldPrefix, newPrefix)
    end
  elseif cname == "Matricks1Value" or cname == "Matricks2Value" or cname == "Matricks3Value" then
    handle_matricks_value_change(caller)
  end
end

-- SIGNAL TABLE - Event Handlers
signalTable.cmdbar_clicked = function()
  if not is_valid_ui_item(UI_MENU_NAME, "ScreenOverlay") then
    local ov = GetTopOverlay(1)
    create_menu()
    local ov = GetTopOverlay(1)
    FindBestFocus(ov)
  else
    local menu = GetDisplayByIndex(1).ScreenOverlay:Ptr(get_ui_item_index(UI_MENU_NAME, "ScreenOverlay"))
    if menu then menu.Visible = "Yes" end
  end
end

signalTable.open_settings = function(caller)
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  overlay:FindRecursive(UI_MENU_NAME).Visible = "No"
  local setting = overlay:Append('BaseInput')
  setting.Name = UI_SETTINGS_NAME
  setting.SuppressOverlayAutoclose = "Yes"
  setting.AutoClose = "No"
  setting.CloseOnEscape = "Yes"

  local path, filename = resolve_xml_file("settings")
  setting:Import(path, filename)

  -- load stored values into Settings UI
  load_state(setting)
  setting:HookDelete(signalTable.close, UI_SETTINGS_NAME)

  local buttons = {
    { "CloseBtn", "close" },
    { "Close",    "close" },
    { "Apply",    "apply" },
  }
  for _, b in ipairs(buttons) do
    if not add_ui_element(b[1], setting, "button", { clicked = b[2] }) then
      ErrPrintf("error at %s", b)
    end
  end

  local texts = {
    { "MatricksStartIndex", "text" },
    { "RefreshRateValue",   "text", "1" },
  }
  for _, t in ipairs(texts) do
    if not add_ui_element(t[1], setting, "textbox",
          { content = get_global("TM_MatricksStartIndex", "1") }) then
      ErrPrintf("error at %s", t)
    end
  end

  load_state(setting)
  save_state()
  coroutine.yield(0.1) -- slight delay to ensure UI is ready
  FindBestFocus(setting:FindRecursive("MatricksStartIndex"))
end

signalTable.plugin_off = function(caller)
  pluginRunning = false
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  if ov then
    local on = ov:FindRecursive("PluginOn")
    local off = ov:FindRecursive("PluginOff")
    local titleicon = ov:FindRecursive("TitleButton")
    if not on or not off then return end
    on.BackColor, off.BackColor, on.TextColor, off.TextColor = colors.button.default, colors.button.clear,
        colors.text.white, colors.icon.active
    titleicon.IconColor = "Button.Icon"
  end
  local cmdicon = GetDisplayByIndex(1).CmdLineSection:FindRecursive(UI_CMD_ICON_NAME)
  if cmdicon then
    cmdicon.IconColor = "Button.Icon"
  end
end

signalTable.plugin_on = function(caller)
  pluginRunning = true
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local off = ov:FindRecursive("PluginOff")
  local on = ov:FindRecursive("PluginOn")
  local titleicon = ov:FindRecursive("TitleButton")
  local cmdicon = GetDisplayByIndex(1).CmdLineSection:FindRecursive(UI_CMD_ICON_NAME)
  if not on or not off then return end
  off.BackColor, on.BackColor, off.TextColor, on.TextColor = colors.button.default, colors.button.please,
      colors.text.white, colors.icon.active
  titleicon.IconColor = "Button.ActiveIcon"
  cmdicon.IconColor = "Button.ActiveIcon"
end

signalTable.master_swap = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local timing, speed, master = ov:FindRecursive("TimingMaster"), ov:FindRecursive("SpeedMaster"),
      ov:FindRecursive("MasterValue")
  if master.Content == "" then
    local isTiming = caller == timing
    timing.State = isTiming and 1 or 0
    speed.State = isTiming and 0 or 1
    master.Content = ""
    save_state()
    return
  end
  if caller.State ~= 1 then
    if Confirm("Override!", "Are you sure you want to override\nyour currently entered Master and use " .. caller.Name .. "?", nil, true) then
      local isTiming = caller == timing
      timing.State = isTiming and 1 or 0
      speed.State = isTiming and 0 or 1
      master.Content = ""
      save_state()
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
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local newState = (caller:Get("State") == 1) and 0 or 1
  caller:Set("State", newState)

  local enable = (newState == 1) and "Yes" or "No"
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
    local prefixField = ov:FindRecursive("MatricksPrefixValue")
    local prefix = prefixField and (prefixField.Content or "") or ""
    if prefix == "" then
      save_state()
      return
    end

    local matricksPool = DataPool(1).Matricks
    local targetNotes = {
      ["TimeMatricks 1.1"] = true,
      ["TimeMatricks 1.2"] = true,
      ["TimeMatricks 1.3"] = true,
      ["TimeMatricks 2.1"] = true,
      ["TimeMatricks 2.2"] = true,
      ["TimeMatricks 2.3"] = true,
      ["TimeMatricks 3.1"] = true,
      ["TimeMatricks 3.2"] = true,
      ["TimeMatricks 3.3"] = true,
    }

    for i = 1, 10000 do
      local obj = matricksPool:Ptr(i)

      if obj then
        local note = obj:Get("Note")
        if note and targetNotes[note] then
          local name = obj:Get("Name") or ""
          if newState == 0 then
            -- Remove prefix if present
            if name:sub(1, #prefix) == prefix then
              local stripped = name:sub(#prefix + 1)
              if stripped ~= "" then
                obj:Set("Name", stripped)
              end
            end
          else
            -- Add prefix if missing
            if name:sub(1, #prefix) ~= prefix then
              obj:Set("Name", prefix .. name)
            end
          end
        end
      end
    end
  end
  save_state()
end

local function update_fade_buttons()
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local fadeLess = ov:FindRecursive("FadeLess")
  local fadeMore = ov:FindRecursive("FadeMore")
  local fadeAmount = ov:FindRecursive("FadeAmount")
  local min, max = 230, 470

  if fadeLess and fadeMore and fadeAmount then
    local size = fadeAmount[2][1]:Get("Size")
    if fadeLess:Get("Enabled", Enums.Roles.Default) == "No" or fadeMore:Get("Enabled", Enums.Roles.Default) == "No" then
      fadeLess:Set("Text", "Fade Disabled")
      fadeMore:Set("Text", "(Click to enable)")
    elseif tonumber(size) == min then
      fadeLess:Set("Text", "MIN")
      fadeLess.Font = "Medium20"
      fadeMore:Set("Text", "Fade More")
      fadeMore.Font = "Regular18"
    elseif tonumber(size) == max then
      fadeMore:Set("Text", "MAX")
      fadeMore.Font = "Medium20"
      fadeLess:Set("Text", "Fade Less")
      fadeLess.Font = "Regular18"
    else
      fadeLess:Set("Text", "Fade Less")
      fadeLess.Font = "Regular18"
      fadeMore:Set("Text", "Fade More")
      fadeMore.Font = "Regular18"
    end
  end
end

signalTable.ShowWarning = function(caller, status, creator)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local ov2 = GetDisplayByIndex(1).ScreenOverlay:FindRecursive("Settings Menu")
  if ov == caller:Parent():Parent():Parent() then
    local ti = ov.TitleBar.WarningButton
    ti.ShowAnimation(status)
  elseif ov2 == caller:Parent():Parent():Parent() then
    local ti = ov2.TitleBar.WarningButton
    ti.ShowAnimation(status)
  end
  -- ErrPrintf(status)
  if pluginError then
    pluginError = nil
    coroutine.yield(0.2)
    FindNextFocus(true)
  end
end

signalTable.ShowWarning2 = function(caller, status, creator)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local ov2 = GetDisplayByIndex(1).ScreenOverlay:FindRecursive("Settings Menu")
  if ov == caller:Parent():Parent():Parent() then
    local ti = ov:FindRecursive("WarningButton2")
    ti.ShowAnimation(status)
  elseif ov2 == caller:Parent():Parent():Parent() then
    local ti = ov2:FindRecursive("WarningButton2")
    ti.ShowAnimation(status)
  end
end

signalTable.close = function(caller)
  -- save_state()
  if caller and caller.Name == "Close" then
    Keyboard(1, "press", "Escape")
    Keyboard(1, "release", "Escape")
    local ov = GetDisplayByIndex(1).ScreenOverlay
    local menu = ov:FindRecursive(UI_MENU_NAME)
    menu.Visible = "Yes"
  else
    local ov = GetDisplayByIndex(1).ScreenOverlay
    local menu = ov:FindRecursive(UI_MENU_NAME)
    if menu then
      menu.Visible = "Yes"
    end
  end
end

signalTable.apply = function(caller)
  -- Printf("Settings Applied")
  save_state()
  signalTable.ShowWarning2(caller, "")
  FindNextFocus()
end

signalTable.Confirm = function(caller)
  local overlay = GetDisplayByIndex(1).ScreenOverlay
  if caller == overlay.FindRecursive(UI_MENU_NAME) then
    signalTable.close(caller)
  elseif caller == overlay.FindRecursive(UI_SETTINGS_NAME) then
    signalTable.close(caller)
  end
end

signalTable.sanitize = function(caller)
  local before = caller.Content or ""
  local after = before

  if caller.Name == "MasterValue" then
    after = after:gsub("[^%d]", "")

    if after ~= "" then
      local num = tonumber(after)
      local after = tonumber(after)
      if num then
        if get_global("TM_TimingMaster") == 1 then
          if num < 1 then
            after = 1
          elseif num > 50 then
            after = 50
          end
        elseif get_global("TM_SpeedMaster", "0") == 1 then
          if num < 1 then
            after = 1
          elseif num > 16 then
            after = 16
          end
        end
      end
    end
  else
    after = sanitize_text(before)
  end

  if before ~= after then
    caller.Content = after
    if caller.HasFocus then
      Keyboard(1, "press", "End")
      Keyboard(1, "release", "End")
      if caller.Name == "MasterValue" and get_global("TM_SpeedMaster") == 1 then
        signalTable.ShowWarning(caller, "Speed Master: 1-16")
      elseif caller.Name == "MasterValue" and get_global("TM_TimingMaster") == 1 then
        signalTable.ShowWarning(caller, "TimingMaster: 1-50")
      else
        signalTable.ShowWarning(caller, "Allowed format: x.xx")
      end
    end
  end
end

signalTable.LineEditSelectAll = function(caller)
  if not caller then return end
  caller:SelectAll()

  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  if not ov then return end

  local fieldNames = {
    "Matricks1Value",
    "Matricks2Value",
    "Matricks3Value",
    "Matricks1Rate",
    "Matricks2Rate",
    "Matricks3Rate",
    "MatricksPrefixValue",
    "MasterValue"
  }

  local function isRate(name)
    return name:match("^Matricks%dRate$")
  end

  for _, name in ipairs(fieldNames) do
    if name ~= caller.Name and not isRate(name) then
      local el = ov:FindRecursive(name)
      if el then
        -- Deselect if it somehow has focus
        if el.HasFocus then el:Deselect() end
        -- Restore unsaved edits back to stored global
        local saved = get_global("TM_" .. name, el.Content or "")
        if (el.Content or "") ~= saved then
          el.Content = saved
          signalTable.ShowWarning(caller, "NOT SAVED! Restored saved value")
        end
      end
    end
  end
end

signalTable.LineEditDeSelect = function(caller)
  caller.Deselect();
  -- save_state()
end

signalTable.ExecuteOnEnter = function(caller, dummy, keyCode)
  if caller.HasFocus and keyCode == Enums.KeyboardCodes.Enter then
    signalTable.LineEditDeSelect(caller)
    -- save_state()
    do
      local n = caller and caller.Name
      if n == "Matricks1Value" or n == "Matricks2Value" or n == "Matricks3Value" or n == "MatricksPrefixValue" then
        matricks_handler(caller)
      elseif n == "MasterValue" or n == "RefreshRateValue" or n == "MatricksStartIndex" then
        save_state()
      end
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
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local rate = ov:FindRecursive("OverallScaleValue")
  rate.Text = 1
  save_state()
end

signalTable.rate_mod = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local rate = ov:FindRecursive("OverallScaleValue")
  if caller.Name == "HT" and tonumber(rate:Get("Text")) > 0.125 then
    local newValue = tonumber(rate.Text or "1") * 0.5
    if math.floor(newValue) == newValue then
      rate.Text = tostring(math.floor(newValue))
    else
      rate.Text = tostring(newValue)
    end
  elseif caller.Name == "DT" and tonumber(rate:Get("Text")) < 8 then
    local newValue = tonumber(rate.Text or "1") * 2
    if math.floor(newValue) == newValue then
      rate.Text = tostring(math.floor(newValue))
    else
      rate.Text = tostring(newValue)
    end
  end
  save_state()
end

signalTable.fade_adjust = function(caller)
  local direction
  if caller.Name == "FadeLess" then
    direction = -1
  elseif caller.Name == "FadeMore" then
    direction = 1
    -- If FadeLess is disabled, enable it when clicking FadeMore
    local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
    local fadeLess = ov:FindRecursive("FadeLess")
    if fadeLess:Get("Enabled", Enums.Roles.Default) == "No" then
      fadeLess:Set("Enabled", "Yes")
      set_global("TM_FadeToggle", "1")
      update_fade_buttons()
    end
  else
    return
  end

  fade_adjust(direction, caller)
  save_state()
end

signalTable.fade_hold = function(caller)
  local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
  local less = ov:FindRecursive("FadeLess")
  local en = less:Get("Enabled", Enums.Roles.Default)
  if en == "Yes" then
    less:Set("Enabled", "No")
    set_global("TM_FadeToggle", "0")
    update_fade_buttons()
    save_state()
  elseif en == "No" then
    less:Set("Enabled", "Yes")
    set_global("TM_FadeToggle", "1")
    update_fade_buttons()
    save_state()
  end
end


-- MAIN LOOP FUNCTIONS
local function plugin_loop()
  pluginAlive = true
  if pluginRunning then
    local mxPool = DataPool(1).Matricks
    local mstr = MasterPool()
    local v = {
      m1t = get_global("TM_Matricks1Button", "") or 0,
      m1r = get_global("TM_Matricks1Rate", "0.25") or 0.25,
      m1v = get_global("TM_Matricks1Value", "") or "",
      m2t = get_global("TM_Matricks2Button", "") or 0,
      m2r = get_global("TM_Matricks2Rate", "0.5") or 0.5,
      m2v = get_global("TM_Matricks2Value", "") or "",
      m3t = get_global("TM_Matricks3Button", "") or 0,
      m3r = get_global("TM_Matricks3Rate", "1") or 1,
      m3v = get_global("TM_Matricks3Value", "") or "",
      mpt = get_global("TM_MatricksPrefixButton", "") or 0,
      mpv = get_global("TM_MatricksPrefixValue", "") or "",
      mv = get_global("TM_MasterValue", "") or "",
      mt = get_global("TM_TimingMaster", "") or 0,
      ms = get_global("TM_SpeedMaster", "") or 0,
      os = get_global("TM_OverallScaleValue", "1") or 1,
      ft = get_global("TM_FadeToggle", "0") or 0,
      fv = get_global("TM_FadeValue", "0.5") or 0.5,
    }

    if (v.mv ~= nil and v.mv ~= "") and ((tonumber(v.mt) == 1) or (tonumber(v.ms) == 1)) then
      local m
      if v.mt == 1 then
        m = mstr.Timing
      elseif v.ms == 1 then
        m = mstr.Speed
      end
      local mstrItem = m and m:Ptr(tonumber(v.mv))
      if mstrItem then
        local normed = mstrItem:GetFader({}) or 0
        if v.mt == 1 then
          normed = normed / 10
          normed = math.floor(normed * 100 + 0.5) / 100
        elseif v.ms == 1 then
          local bpm = BPM_quartic(normed)
          normed = 60 / bpm
          normed = math.floor(normed * 100 + 0.5) / 100
        end
        normed = normed / v.os

        -- helper to apply rate to the triplet (k=1..3)
        local function apply_triplet(baseName, rate)
          if baseName == "" then return end
          local usePrefix = (tonumber(v.mpt) == 1) and (v.mpv ~= "")
          local prefix = usePrefix and v.mpv or ""
          local d = normed * rate

          -- Split d into fade and delay
          local fade, delay
          if tonumber(v.ft) == 0 then
            fade = "None"
            delay = d
          else
            fade = d * tonumber(v.fv)
            delay = d * (1 - tonumber(v.fv))
          end

          for k = 1, 3 do
            local fullName = prefix .. baseName .. " " .. k
            local obj = mxPool:Find(fullName)
            if obj then
              obj:Set("FadeFromX", fade)
              obj:Set("DelayFromX", delay)
              obj:Set("DelayToX", 0)
            end
          end
        end

        if v.m1t == 1 then apply_triplet(v.m1v, tonumber(v.m1r) or 0.25) end
        if v.m2t == 1 then apply_triplet(v.m2v, tonumber(v.m2r) or 0.5) end
        if v.m3t == 1 then apply_triplet(v.m3v, tonumber(v.m3r) or 1.0) end
      end
    end
  end
  local refreshrate = tonumber(get_global("TM_RefreshRateValue", "1")) or 1
  coroutine.yield(refreshrate)
end

local function plugin_kill()
  pluginAlive = false
  signalTable.plugin_off()
  local ov = GetDisplayByIndex(1).ScreenOverlay
  local menu = ov:FindRecursive(UI_MENU_NAME)
  if menu then
    FindBestFocus(menu)
    Keyboard(1, "press", "Escape")
    Keyboard(1, "release", "Escape")
  end
  delete_CMDlineIcon()
  -- save_state()
  local temp = GetPath("temp", false)
  local uixml = temp .. "/TimeMAtricks_UI.xml"
  local settingsxml = temp .. "/TimeMAtricks_Settings_UI.xml"
  if FileExists(uixml) then
    os.remove(uixml)
    Echo("Removed " .. uixml)
  end
  if FileExists(settingsxml) then
    os.remove(settingsxml)
    Echo("Removed " .. settingsxml)
  end
end

-- MAIN ENTRY POINT
local function main()
  Printf("FileTest")
  if not pluginAlive or nil then
    if is_valid_ui_item(UI_CMD_ICON_NAME, "CmdLineSection") then
      pluginAlive = true
    else
      pluginAlive = false
      create_CMDlineIcon()
      if not DataPool(1).Macros:FindRecursive("TimeMAtricks Reset") then
        if not create_panic_macro() then
          ErrPrintf("Failed to create panic macro")
        end
      end
    end
    signalTable.cmdbar_clicked()
    local frststrt = get_global("TM_FirstStart", nil)
    if not frststrt then
      local messageBoxSettings = {
        title = "First Launch",
        message = "Press the Settings button at the top to configure the starting MAtricks pool number.",
        commands = { { value = 1, name = "Ok" } },
        icon = "QuestionMarkIcon",
        timeout = 10000,
        backColor = "Window.Plugins",
      }
      MessageBox(messageBoxSettings)
      --[[ Confirm("First Launch", "Press the Settings button at the top\nto configure where the MAtricks should be stored",
        nil, false) ]]
      local menu = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(UI_MENU_NAME)
      local setbtn = menu:FindRecursive("SettingsBtn")
      if setbtn then
        FindNextFocus(true)
        FindNextFocus(true)
      end
    end
    set_global("TM_FirstStart", true)
    Timer(plugin_loop, 0, 0, plugin_kill)
  else
    signalTable.cmdbar_clicked()
    return
  end
end

return main
