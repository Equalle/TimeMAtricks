# Main

fix prefix toggle button
check matricks123 toggle buttons
fix bugs in ui and signals cmdbar swipey and menu open errors (bottom of file)

total cleanup

### Add

documentation

### Remove

-yields
-prints

## Later

-add save
-create repo for compiling
-add compiling
-compiling has the issue, that SignalTable did not work properly after compiling
-maybe find a way to reinitialize signals after compiling

## Extra

-add SpeedtoTime integration

LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_ui.lua:121: attempt to index a nil value (field 'CMD_ICON')
23h02m04.319s LUA : stack traceback:
23h02m04.319s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_ui.lua:121: in field 'load'
23h02m04.319s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:138: in field 'open_menu'
23h02m04.319s LUA : [string "TM with mods@TimeMAtricks X.lua"]:245: in function <[string "TM with mods@TimeMAtricks X.lua"]:231>
23h02m07.688s MainTask : OK:Toggle Plugin 7
23h02m07.781s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_ui.lua:121: attempt to index a nil value (field 'CMD_ICON')
23h02m07.781s LUA : stack traceback:
23h02m07.781s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_ui.lua:121: in field 'load'
23h02m07.781s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:138: in field 'open_menu'
23h02m07.781s LUA : [string "TM with mods@TimeMAtricks X.lua"]:261: in function <[string "TM with mods@TimeMAtricks X.lua"]:231>
23h02m15.275s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: attempt to index a nil value (field 'CMD_ICON')
23h02m15.275s LUA : stack traceback:
23h02m15.275s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: in function <C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:166>
23h02m22.247s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: attempt to index a nil value (field 'CMD_ICON')
23h02m22.247s LUA : stack traceback:
23h02m22.247s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: in field 'close_small'
23h02m22.247s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:239: in function <C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:213>
23h02m22.543s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: attempt to index a nil value (field 'CMD_ICON')
23h02m22.543s LUA : stack traceback:
23h02m22.543s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: in function <C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:166>
23h02m24.220s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: attempt to index a nil value (field 'CMD_ICON')
23h02m24.220s LUA : stack traceback:
23h02m24.220s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: in field 'close_small'
23h02m24.220s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:206: in function <C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:180>
23h02m24.506s LUA : LUA Runtime ErrorC:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: attempt to index a nil value (field 'CMD_ICON')
23h02m24.506s LUA : stack traceback:
23h02m24.506s LUA : C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:172: in function <C:/ProgramData/MALightingTechnology/gma3_2.3.0/shared/resource/lib_plugins\TimeMAtricks\TM_signals.lua:166>
