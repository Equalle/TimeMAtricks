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
