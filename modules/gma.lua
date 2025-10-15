---@diagnostic disable: redundant-parameter

GMA = {}

--returns version: "x.x.x.x" "x" ".x" "..x" "...x"
function GMA.get_version()
  local text, major, minor, streaming, ui = Version()
  return text, major, minor, streaming, ui
end

function GMA.set_globalV(var, value)
  return SetVar(GlobalVars(), var, value)
end

function GMA.get_globalV(var)
  return GetVar(GlobalVars(), var)
end

GMA.GVars = {
  GMA.get_globalV("TM_mvalue"),
  GMA.get_globalV("TM_timing"),
  GMA.get_globalV("TM_speed"),
  GMA.get_globalV("TM_mx1name"),
  GMA.get_globalV("TM_mx2name"),
  GMA.get_globalV("TM_mx3name"),
  GMA.get_globalV("TM_mx1rate"),
  GMA.get_globalV("TM_mx2rate"),
  GMA.get_globalV("TM_mx3rate"),
  GMA.get_globalV("TM_mx1"),
  GMA.get_globalV("TM_mx2"),
  GMA.get_globalV("TM_mx3"),
  GMA.get_globalV("TM_prefixname"),
  GMA.get_globalV("TM_prefix"),
  GMA.get_globalV("TM_mxstart"),
  GMA.get_globalV("TM_refresh"),
  GMA.get_globalV("TM_fadeamount"),
  GMA.get_globalV("TM_fade"),
  GMA.get_globalV("TM_ovrate"),
  GMA.get_globalV("TM_firststart")
}

function GMA.set_userV(var, value)
  return SetVar(UserVars(), var, value)
end

function GMA.get_userV(var)
  return GetVar(UserVars(), var)
end

--create reset macro for beta testers
function GMA.reset_macro()
  local macroPool = DataPool(1).Macros
  local macro = macroPool:Acquire()

  if not macro then
    return false
  end

  macro.Name = "TimeMAtricks Reset"
  macro.Note = "Resets all TimeMAtricks settings to default values"

  for _, var in ipairs(C.GVars) do
    local line = macro:Append()
    if line then
      line:Set("Command", 'DeleteGlobalVariable "' .. var .. '"')
    end
  end
  Printf("Created 'TimeMAtricks Reset' Macro")
  Printf("Use to reset all TimeMAtricks settings")
end

function GMA.msgbox(table)
  local settings = table or {}
  MessageBox(settings)
end

function GMA.echo(message)
  Echo("GMA READY!")
end

return GMA
