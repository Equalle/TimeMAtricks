---@diagnostic disable redundant-parameter

S = {}

----------
-- MENU --
----------

SignalTable.open_menu = function()
    if not UI.is_valid_item(C.UI_MENU_NAME, "screenOV") then
        UI.create_menu()
        FindBestFocus(GetTopOverlay(1))
    else
        UI.edit_element(C.UI_MENU_NAME, "Visible", "YES")
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

-------------
-- BUTTONS --
-------------

SignalTable.plugin_off = function()
    PluginRunning = false
    UI.edit_element("PlOn", {
        BackColor = C.colors.button.default,
        TextColor = C.colors.icon.inactive
    })

    UI.edit_element("PlOff", {
        BackColor = C.colors.button.clear,
        TextColor = C.colors.icon.active
    })

    UI.edit_element("TitleButton", {
        IconColor = C.colors.icon.inactive,
    })

    C.CMD_ICON.IconColor = C.colors.icon.inactive
end

SignalTable.plugin_on = function()
    PluginRunning = true
    UI.edit_element("PlOn", {
        BackColor = C.colors.button.please,
        TextColor = C.colors.icon.active
    })

    UI.edit_element("PlOff", {
        BackColor = C.colors.button.default,
        TextColor = C.colors.icon.inactive
    })

    UI.edit_element("TitleButton", {
        IconColor = C.colors.icon.active,
    })

    C.CMD_ICON.IconColor = C.colors.icon.active
end

SignalTable.set_master = function(caller)
    if caller and caller.Name == "MstTiming" then
        GMA.set_globalV(C.GVars.timing, 1)
        GMA.set_globalV(C.GVars.speed, 0)

        UI.edit_element("MstTiming", {
            TextColor = C.colors.icon.active
        })
        UI.edit_element("MstSpeed", {
            TextColor = C.colors.icon.inactive
        })
    elseif caller and caller.Name == "MstSpeed" then
        GMA.set_globalV(C.GVars.timing, 0)
        GMA.set_globalV(C.GVars.speed, 1)

        UI.edit_element("MstTiming", {
            TextColor = C.colors.icon.inactive
        })
        UI.edit_element("MstSpeed", {
            TextColor = C.colors.icon.active
        })
    end
end

SignalTable.matricks_toggle = function(caller)
    -- Code to toggle matricks
    Echo(">PH<   toggle_matricks")
end

SignalTable.fade_change = function(caller)
    -- Code to change fade
    Echo(">PH<   fade_change")
end

----------
-- HOLD --
----------

SignalTable.fade_toggle = function(caller)
    -- Code to toggle fade
    Echo(">PH<   fade_toggle")
end

SignalTable.rate_change = function(caller)
    -- Code to change rate
    Echo(">PH<   rate_change")
end

SignalTable.apply_changes = function(caller)
    -- Code to apply changes
    Echo(">PH<   apply_changes")
end

--------------
-- LINEEDIT --
--------------

SignalTable.text_master = function(caller)
    if caller then
        Echo("%s: %s", caller.Name, caller.Content)
    end
end

SignalTable.text_rate = function(caller)
    if caller then
        Echo("%s: %s", caller.Name, caller.Content)
    end
end

SignalTable.key_down = function(caller, dummy, keycode)
    if caller.HasFocus and keycode == Enums.KeyboardCodes.Enter then
        Echo("Enter -> %s: %s", caller.Name, caller.Content)
    end
end

-- FOCUS

SignalTable.LineEditSelectAll = function(caller)
    if caller then
        caller:SelectAll()
        Echo("%s selected", caller.Name)
    end
end

SignalTable.LineEditDeselect = function(caller)
    if caller then
        caller:Deselect()
        ErrEcho("%s deselected", caller.Name)
    end
end

-- Debug
function S.echo(message)
    Echo("SIGNALS READY!")
end

return S
