---@diagnostic disable: redundant-parameter

GMA = {}

--returns version: "x.x.x.x" "x" ".x" "..x" "...x"
function GMA.get_version()
  local text, major, minor, streaming, ui = Version()
  return text, major, minor, streaming, ui
end

-- Sets the GrandMA3 global variable
-- var: string name of the variable
-- value: value to set (string, number, boolean)
-- returns: boolean success
function GMA.set_global(var, value)
  return SetVar(GlobalVars(), var, value)
end

-- Gets the GrandMA3 global variable
-- var: string name of the variable
-- returns: value or nil if not found
function GMA.get_global(var)
  return GetVar(GlobalVars(), var)
end

-- Sets the GrandMA3 user variable
-- var: string name of the variable
-- value: value to set (string, number, boolean)
-- returns: boolean success
function GMA.set_user(var, value)
  return SetVar(UserVars(), var, value)
end

-- Gets the GrandMA3 user variable
-- var: string name of the variable
-- returns: value or nil if not found
function GMA.get_user(var)
  return GetVar(UserVars(), var)
end

-- Simulates a key press on the GrandMA3 keyboard
-- key: string name of the key (e.g. "F1", "ENTER", "ESC", "LEFT", "RIGHT", "A" etc.)
-- modifier: table with boolean fields shift, ctrl, alt, numlock (all optional, default false)
function GMA.press_key(key, modifier)
  modifier = modifier or { shift = false, ctrl = false, alt = false, numlock = false }
  Keyboard(1, "press", key, modifier.shift, modifier.ctrl, modifier.alt, modifier.numlock)
  Keyboard(1, "release", key, modifier.shift, modifier.ctrl, modifier.alt, modifier.numlock)
end

----------------------
--SPECIAL FUNCTIONS --
----------------------

function GMA.pool_check()
  local mc = DataPool().Macros:Count()
  local mx = DataPool().MAtricks:Count()
  if not mc or mc < 1 then
    Printf("No Macros found in Data Pool")
    Printf("Create Delete")
    Cmd("Store Macro 9999 /noo")
    Cmd("Delete Macro 9999 /noo")
  end
  if not mx or mx < 1 then
    Printf("No MAtricks found in Data Pool")
    Printf("Create Delete")
    Cmd("Store MAtricks 9999 /noo")
    Cmd("Delete MAtricks 9999 /noo")
  end
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

  for _, var in pairs(C.GVars) do
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

return GMA
