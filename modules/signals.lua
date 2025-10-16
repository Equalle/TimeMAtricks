---@diagnostic disable redundant-parameter

S = {}

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

SignalTable.plugin_off = function()
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
