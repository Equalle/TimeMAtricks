---@diagnostic disable: redundant-parameter

XML = {}

function XML.importxml(xmlType)
local slash = "/"
local base = GetPath("temp") or ""

-- Create plugin-specific subfolder for XML files
local pluginFolder = "TimeMAtricks"
local dir = base .. slash .. pluginFolder .. slash

-- Create directory if it doesn't exist
local success = CreateDirectoryRecursive(dir)
if not success then
ErrEcho("Failed to create XML directory: %s", dir)
return nil
end

local filename, content

if xmlType == "ui" then
filename = tostring(C.UI_MENU_NAME) .. ".xml"
content = XML.UI_MENU
elseif xmlType == "ui_settings" then
filename = tostring(C.UI_SETTINGS_NAME) .. ".xml"
content = XML.UI_SETTINGS
else
ErrEcho("XML.import: Unknown xmlType '%s'", tostring(xmlType))
return
end

local fullPath = dir .. filename

-- Always try to create the file (overwrite if exists)
local file, err = io.open(fullPath, "w")
if file then
file:write(content)
file:close()
Echo("Created XML file: %s", fullPath)
else
ErrEcho("Failed to create XML file: %s (Error: %s)", fullPath, tostring(err))
return nil
end

return dir, filename
end


XML.UI_MENU = [[
<?xml version="1.0" encoding="UTF-8"?>
<GMA3 DataVersion="0.0.1">
  <BaseInput Name="TimeMAtricks_Menu" H="0" W="700" AlignmentH="Center" AlignmentV="Center" Focus="InitialFocus" CanCoexistWithModal="Yes" BlockClickThru="Yes" SuppressOverlayAutoClose="Yes" HideFocusFrame="Yes" CloseOnEscape="Yes">
    <ItemCollectRows>
      <Item SizePolicy="Fixed" Size="50" />
      <!-- Title Bar -->
      <Item SizePolicy="Stretch" />
      <!-- Main Content -->
    </ItemCollectRows>

    <!-- Title Bar  -->
    <TitleBar Name="TitleBar" Anchors="0,0">
      <ItemCollectRows>
        <Item SizePolicy="Fixed" Size="50" />
        <!-- Title Bar -->
      </ItemCollectRows>
      <ItemCollectColumns>
        <Item SizePolicy="Stretch" Size="0" />
        <!-- Title -->
        <Item SizePolicy="Fixed" Size="50" />
        <!-- Close -->
      </ItemCollectColumns>
      <TitleButton Name="TitleButton" Anchors="0,0" Texture="corner1" />
      <CloseButton Name="CloseButton" Anchors="1,0" Texture="corner2" />
      <WarningInfoButton Name="WarningButton" Anchors="0,0,2,0" Font="Regular32" BackColor="Global.AlertText" />
    </TitleBar>

    <!-- Main Content -->
    <DialogFrame Name="Main" Anchors="0,1">
      <ItemCollectRows>
        <Item SizePolicy="Fixed" Size="30" />
        <!-- Version -->
        <Item SizePolicy="Content" />
        <!-- Plugin Off/On -->
        <Item SizePolicy="Fixed" Size="35" />
        <!-- Settings -->
        <Item SizePolicy="Content" />
        <!-- Master Buttons -->
        <Item SizePolicy="Content" />
        <!-- Matricks Prefix -->
        <Item SizePolicy="Content" />
        <!-- Matricks List -->
        <Item SizePolicy="Fixed" Size="40" />
        <!-- Fade Title -->
        <Item SizePolicy="Content" />
        <!-- Fade -->
        <Item SizePolicy="Fixed" Size="30" />
        <!-- Scale Title -->
        <Item SizePolicy="Content" />
        <!-- Scale -->
        <Item SizePolicy="Content" />
        <!-- Bottom Buttons -->
      </ItemCollectRows>

      <!-- Version -->
      <Button Name="Version" Text="Version (should not be here!)" Anchors="0,0" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />

      <!-- Plugin Off/On Buttons -->
      <UILayoutGrid Name="PluginButtons" Anchors="0,1" Padding="10,10,10,10">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="80" />
          <!-- Plugin Buttons -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Stretch" />
          <!-- Plugin Off-->
          <Item SizePolicy="Stretch" />
          <!-- Plugin On-->
        </ItemCollectColumns>

        <Button Name="PlOff" Text="Plugin Off" Anchors="0,0" Texture="corner5" Focus="Never" TextShadow="Yes" Font="Medium20" />
        <Button Name="PlOn" Text="Plugin On" Anchors="1,0" Texture="corner10" Focus="Never" TextShadow="Yes" Font="Medium20" />
      </UILayoutGrid>

      <!-- Settings -->
      <Button Text="Settings" Anchors="0,2" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />

      <!-- Master -->
      <UILayoutGrid Name="Master" Anchors="0,3" Padding="10,10,10,">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="60" />
          <!-- Master Row -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Stretch" />
          <!-- Timing -->
          <Item SizePolicy="Stretch" />
          <!-- Speed -->
          <Item SizePolicy="Fixed" Size="325" />
          <!-- Master ID -->
        </ItemCollectColumns>

        <Button Name="MstTiming" Text="Timing Master" Anchors="0,0" Texture="corner5" Focus="Never" />
        <Button Name="MstSpeed" Text="Speed Master" Anchors="1,0" Texture="corner10" Focus="Never" />
        <LineEdit Name="Master ID" Message="Obj Number" Anchors="2,0" Padding="0,0,10,0" Texture="corner15" Icon="master" IconAlignmentH="Right" IconAlignmentV="Center" />
      </UILayoutGrid>

      <!-- Matricks Prefix -->
      <UILayoutGrid Name="MatricksPrefix" Anchors="0,4" Padding="10,5,170,0">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="55" />
          <!-- Matricks Prefix -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Fixed" Size="180" />
          <Item SizePolicy="Stretch" />
        </ItemCollectColumns>

        <CheckBox Name="Matricks Prefix" Text="Matricks Prefix" TextAlignmentH="Left" Anchors="0,0" Texture="corner5" Focus="Never" />
        <LineEdit Name="Matricks Prefix Name" Anchors="1,0" Texture="corner10" />
      </UILayoutGrid>

      <!-- Matricks -->
      <UILayoutGrid Name="Matricks" Anchors="0,5" Padding="10,10,10,10">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="25" />
          <!-- Title Row -->
          <Item SizePolicy="Fixed" Size="50" />
          <!-- Matricks 1 -->
          <Item SizePolicy="Fixed" Size="50" />
          <!-- Matricks 1 -->
          <Item SizePolicy="Fixed" Size="50" />
          <!-- Matricks 1 -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Fixed" Size="180" />
          <!-- Toggle -->
          <Item SizePolicy="Stretch" Name="Name" />
          <!-- Name -->
          <Item SizePolicy="Fixed" Size="160" />
          <!-- Rate -->
        </ItemCollectColumns>

        <Button Text="Toggle" Anchors="0,0" Texture="corner1" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />
        <Button Text="Name" Anchors="1,0" HasHover="No" Focus="Never" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />
        <Button Text="Rate" Anchors="2,0" Texture="corner2" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />

        <CheckBox Name="Matricks 1" Text="Matricks 1" TextAlignmentH="Left" Anchors="0,1" Focus="Never" />
        <LineEdit Name="Matricks 1 Name" Message="Suffix 1" Anchors="1,1" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" />
        <LineEdit Name="Matricks 1 Rate" Message="Rate 1" Anchors="2,1" Padding="0,0,10,0" Icon="master" IconAlignmentH="Right" IconAlignmentV="Center" />

        <CheckBox Name="Matricks 2" Text="Matricks 2" TextAlignmentH="Left" Anchors="0,2" Focus="Never" />
        <LineEdit Name="Matricks 2 Name" Message="Suffix 2" Anchors="1,2" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" />
        <LineEdit Name="Matricks 2 Rate" Message="Rate 2" Anchors="2,2" Padding="0,0,10,0" Icon="master" IconAlignmentH="Right" IconAlignmentV="Center" />

        <CheckBox Name="Matricks 3" Text="Matricks 3" TextAlignmentH="Left" Anchors="0,3" Focus="Never" Texture="corner4" />
        <LineEdit Name="Matricks 3 Name" Message="Suffix 3" Anchors="1,3" Padding="0,0,10,0" Icon="object_matricks" IconAlignmentH="Right" IconAlignmentV="Center" />
        <LineEdit Name="Matricks 3 Rate" Message="Rate 3" Anchors="2,3" Padding="0,0,10,0" Icon="master" IconAlignmentH="Right" IconAlignmentV="Center" Texture="corner8" />
      </UILayoutGrid>

      <!-- Fade Title-->
      <Button Name="FadeTitle" Anchors="0,6" Margin="10,0,10,0" Text="Fade Amount (Hold to Disable)" Texture="corner15" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />

      <!-- Fade -->
      <UILayoutGrid Name="Fade" Anchors="0,7" Padding="10,0,10,10">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="75" />
          <!-- Fade -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Fixed" Size="325" Name="Fade Less" />
          <!-- Fade Less -->
          <Item SizePolicy="Stretch" />
          <!-- Fade More -->
        </ItemCollectColumns>

        <Button Name="FadeLess" Text="Fade Less" Anchors="0,0" Texture="corner5" Focus="Never" TextShadow="Yes" Font="Medium20" BackColor="ProgLayer.Fade" />
        <Button Name="FadeMore" Text="Fade More" Anchors="1,0" Texture="corner10" Focus="Never" TextShadow="Yes" Font="Medium20" BackColor="ProgLayer.Delay" />
      </UILayoutGrid>

      <!-- Scale Title -->
      <Button Name="ScaleTitle" Anchors="0,8" Margin="10,0,10,0" Text="Overall Rate" Texture="corner15" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" />

      <!-- Scale -->
      <UILayoutGrid Name="Scale" Anchors="0,9" Padding="10,0,10,10">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="80" />
          <!-- Scale -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Stretch" />
          <!-- HT -->
          <Item SizePolicy="Fixed" Size="250" />
          <!-- Center -->
          <Item SizePolicy="Stretch" />
          <!-- DT -->
        </ItemCollectColumns>


        <Button Name="1/2" Anchors="0,0" Texture="corner5" Icon="ExecuteHalfSpeed84" Focus="Never" />
        <Button Name="OVRate" Text="X" Anchors="1,0" TextAlignmentV="Top" Padding="0,10,0,0" Focus="Never" HasHover="No" HasPressedAnimation="No" BackColor="CheckBox.ReadOnlyBackground" BackColor="CheckBox.ReadOnlyBackground" TextColor="CheckBox.ReadOnlyText" Font="Regular28" TextShadow="Yes" />
        <Button Name="2" Anchors="2,0" Texture="corner10" Icon="ExecuteDoubleSpeed84" Focus="Never" Clicked="dRate"/>

        <Button Name="Reset" Anchors="1,0" Icon="ExecuteRate120" Focus="Never" Margin="80,45,80,0" Texture="corner15" />
      </UILayoutGrid>

      <!-- Bottom Buttons -->
      <UILayoutGrid Name="BottomButtons" Anchors="0,10" Padding="0,0,0,0">
        <ItemCollectRows>
          <Item SizePolicy="Fixed" Size="60" />
          <!-- Bottom Buttons -->
        </ItemCollectRows>
        <ItemCollectColumns>
          <Item SizePolicy="Stretch" />
          <!-- Apply -->
          <Item SizePolicy="Stretch" />
          <!-- Close -->
        </ItemCollectColumns>

        <Button Name="Apply" Text="Apply" Anchors="0,0" Texture="corner5" Focus="Never" TextShadow="Yes" Font="Medium20" />
        <Button Name="Close" Text="Close" Anchors="1,0" Texture="corner10" Focus="Never" TextShadow="Yes" Font="Medium20" />
      </UILayoutGrid>
    </BaseInput>
  </GMA3>
]]

XML.UI_SETTINGS = [[
  <?xml version="1.0" encoding="UTF-8"?>
  <GMA3 DataVersion="0.9.0.1">
    <BaseInput Name="TimeMAtricks Menu" H="0" W="700" AlignmentH="Center" AlignmentV="Center" Focus="InitialFocus" CanCoexistWithModal="Yes" BlockClickThru="Yes" SuppressOverlayAutoClose="Yes" HideFocusFrame="Yes" CloseOnEscape="Yes">

    </BaseInput>
  </GMA3>
]]

function XML.echo(message)
Echo("XML READY!")
end

return XML