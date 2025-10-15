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
  <BaseInput Name="TimeMAtricks Menu" H="0" W="700" AlignmentH="Center" AlignmentV="Center" Focus="InitialFocus" CanCoexistWithModal="Yes" BlockClickThru="Yes" SuppressOverlayAutoClose="Yes" HideFocusFrame="Yes" CloseOnEscape="Yes">
    <ItemCollectColumns>
      <Item SizePolicy="Stretch" Size="0" Name="Content"/>
    </ItemCollectColumns>
    <ItemCollectRows>
      <Item SizePolicy="Fixed" Size="50" Name="TitleBar"/>
      <Item SizePolicy="Fixed" Size="50" Name="TitleBar"/>
    </ItemCollectRows>

    <!-- Title Bar  -->
    <TitleBar Name="TitleBar" Anchors="0,0">
      <ItemCollectRows>
        <Item SizePolicy="Fixed" Size="50" Name="TitleBar"/>
      </ItemCollectRows>
      <ItemCollectColumns>
        <Item SizePolicy="Stretch" Size="0" Name="TitleButton"/>
        <Item SizePolicy="Fixed" Size="50" Name="CloseButton"/>
      </ItemCollectColumns>
      <TitleButton Name="TitleButton" Anchors="0,0" Texture="corner1"/>
      <CloseButton Name="CloseButton" Anchors="1,0" Texture="corner2"/>
      <WarningInfoButton Name="WarningButton" Anchors="0,0,2,0" Font="Regular32" BackColor="Global.AlertText" />
    </TitleBar>

    <!-- Main Content -->
    <DialogFrame Name="MainContent" Anchors="0,1">
      <ItemCollectRows>
        <Item SizePolicy="Fixed" Size="60"/>
      </ItemCollectRows>
      <ItemCollectColumns>
        <Item SizePolicy="Stretch" Size="0" Name="DialogContent"/>
      </ItemCollectColumns>
      <!-- <Button Name="TestButton1" Anchors="0,0" /> -->
    </DialogFrame>

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
