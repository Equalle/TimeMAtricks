---@diagnostic disable redundant-parameter

S = {}

SignalTable.open_menu = function()
    if not UI.is_valid_item(C.UI_MENU_NAME, "screenOV") then
        UI.create_menu()
        FindBestFocus(GetTopOverlay(1))
    else
        UI.fill_element(C.UI_MENU_NAME, "Visible", "YES")
    end
    UI.load()
end

SignalTable.close_menu = function(caller)
    UI.save()
    if C.UI_MENU then
        if caller and caller.Name == "Close" then
            GMA.press_key("Escape")
        end
    elseif caller and caller == C.UI_SETTINGS then
        C.UI_MENU.Visible = "Yes"
    end
end

SignalTable.plugin_off = function()
    -- Code to handle plugin off
    Echo(">PH<   plugin_off")
end

SignalTable.plugin_on = function()
    -- Code to handle plugin on
    Echo(">PH<   plugin_on")
end

SignalTable.set_master = function(caller)
    -- Code to set the master
    Echo(">PH<   set_master")
end

SignalTable.toggle_matricks = function(caller)
    -- Code to toggle matricks
    Echo(">PH<   toggle_matricks")
end

SignalTable.fade_change = function(caller)
    -- Code to change fade
    Echo(">PH<   fade_change")
end

SignalTable.rate_change = function(caller)
    -- Code to change rate
    Echo(">PH<   rate_change")
end

SignalTable.apply_changes = function(caller)
    -- Code to apply changes
    Echo(">PH<   apply_changes")
end

function S.echo(message)
    Echo("SIGNALS READY!")
end

return S
