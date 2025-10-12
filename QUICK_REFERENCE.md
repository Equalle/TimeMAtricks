# TimeMAtricks Quick Reference Card

## 📦 Module Overview

| Module | Lines | Purpose | Key Functions |
|--------|-------|---------|--------------|
| **constants.lua** | 150 | Config & constants | PLUGIN_NAME, colors, icons, corners, fade, master_limits, global_vars |
| **helpers.lua** | 210 | Utilities | get_global(), set_global(), sanitize_text(), bpm_quartic() |
| **state.lua** | 200 | State persistence | save_state(), load_state() |
| **ui_xml.lua** | 380 | XML templates | UI_XML_CONTENT, UI_XML_SETTINGS, resolve_xml_file() |
| **ui.lua** | 420 | UI management | create_menu(), create_cmd_line_icon(), fade_adjust() |
| **matricks.lua** | 350 | Business logic | get_all_matricks(), create_matricks_triplet(), matricks_handler() |
| **TimeMAtricks_NEW.lua** | 645 | Main entry point | load_modules(), signalTable.*, plugin_loop(), main() |

## 🔧 Common Tasks

### Add a New Constant
**File:** `constants.lua`
```lua
-- Add to appropriate section
M.NEW_CONSTANT = "value"
```

### Add a New Helper Function
**File:** `helpers.lua`
```lua
function M.new_function(param1, param2)
  -- Implementation
  return result
end
```

### Add a New Signal Handler
**File:** `TimeMAtricks_NEW.lua`
```lua
signalTable.new_handler = function(caller)
  -- Use modules: C (constants), H (helpers), S (state), X (ui_xml), U (ui), M (matricks)
  local value = H.get_global("TM_Something", "default")
  -- Implementation
end
```

### Modify State Persistence
**File:** `state.lua`
```lua
-- Add field to appropriate table
local UI_FIELDS = {
  -- ... existing fields
  "NewFieldValue",
}
```

### Add UI Element
**File:** `ui.lua` in `create_menu()` function
```lua
-- Add to appropriate array (buttons, checks, texts, etc.)
local buttons = {
  -- ... existing buttons
  { "NewButton", "new_handler" },
}
```

### Add Matricks Logic
**File:** `matricks.lua`
```lua
function M.new_matricks_function(helpers, params)
  local mx_table, mx_path = M.get_all_matricks()
  -- Implementation
  return success
end
```

## 🎯 Module Dependencies

```
TimeMAtricks_NEW.lua (main)
├── constants.lua (C) ─── no dependencies
├── helpers.lua (H) ───── no dependencies
├── state.lua (S) ─────── depends on: H
├── ui_xml.lua (X) ────── depends on: H
├── ui.lua (U) ────────── depends on: C, H, S, X
└── matricks.lua (M) ──── depends on: H
```

**Load Order:** C → H → S → X → U → M ✅

## 🔑 Key Patterns

### Module Structure
```lua
-- ---------------------------------------------------------------------------
-- MODULE: name
-- PURPOSE: description
-- ---------------------------------------------------------------------------

local M = {}

-- ---------------------------------------------------------------------------
-- SECTION TITLE (ALL CAPS)
-- ---------------------------------------------------------------------------

function M.function_name(param1, param2)
  -- Implementation
end

return M
```

### Dependency Injection
```lua
-- Pass dependencies as parameters, don't use globals
function M.my_function(helpers, constants, param)
  local value = helpers.get_global("TM_Value", "default")
  local color = constants.colors.text.white
  -- Use injected dependencies
end
```

### Naming Conventions
```lua
-- snake_case for functions and variables
local my_variable = "value"
function my_function() end

-- SCREAMING_SNAKE_CASE for constants
M.MY_CONSTANT = "value"

-- lowercase for files
-- helpers.lua (not Helpers.lua or helpers_module.lua)
```

### Error Handling
```lua
-- Return success/failure with message
function M.risky_operation(params)
  if not valid then
    return false, "Error message"
  end
  -- Do work
  return true
end

-- Usage:
local success, error_msg = M.risky_operation(params)
if not success then
  show_warning_func(caller, error_msg)
  return
end
```

## 🐛 Debug Helpers

### Check Module Loading
```lua
-- In TimeMAtricks_NEW.lua after load_modules()
Echo("Loaded: C=" .. tostring(C ~= nil) .. 
     ", H=" .. tostring(H ~= nil) .. 
     ", S=" .. tostring(S ~= nil))
```

### Check Global Variables
```lua
-- From any module
local value = helpers.get_global("TM_MasterValue", "not set")
Printf("Master: " .. value)
```

### Check UI Elements
```lua
-- From main file or ui module
local ov = GetDisplayByIndex(1).ScreenOverlay:FindRecursive(C.UI_MENU_NAME)
local el = ov and ov:FindRecursive("ElementName")
Printf("Found: " .. tostring(el ~= nil))
```

### Check Matricks
```lua
-- From matricks module or main
local mx_table, mx_path = M.get_all_matricks()
Printf("Found " .. #mx_table .. " matricks")
```

## 📍 File Locations

**Development:**
```
/Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks/
├── TimeMAtricks_NEW.lua (main file to test)
├── TimeMAtricks.lua.backup (original backup)
└── modules/
    ├── constants.lua
    ├── helpers.lua
    ├── state.lua
    ├── ui_xml.lua
    ├── ui.lua
    └── matricks.lua
```

**Runtime (copied automatically):**
```
/Users/juriseiffert/MALightingTechnology/gma3_library/datapools/plugins/
└── TimeMAtricks_modules/
    ├── constants.lua
    ├── helpers.lua
    ├── state.lua
    ├── ui_xml.lua
    ├── ui.lua
    └── matricks.lua
```

**XML Files (created automatically):**
```
/Users/juriseiffert/MALightingTechnology/gma3_library/datapools/temp/
├── TimeMAtricks_UI.xml
└── TimeMAtricks_Settings_UI.xml
```

## 🚀 Quick Deploy

```bash
cd /Users/juriseiffert/Documents/GrandMA3Plugins/TimeMAtricks

# Test new version
mv TimeMAtricks.lua TimeMAtricks_OLD.lua
mv TimeMAtricks_NEW.lua TimeMAtricks.lua

# Run in GrandMA3 and test...

# If success:
rm TimeMAtricks_OLD.lua

# If failure:
rm TimeMAtricks.lua
mv TimeMAtricks_OLD.lua TimeMAtricks.lua
```

## 📊 Module API Quick Reference

### constants.lua
```lua
C.PLUGIN_NAME              -- "TimeMAtricks"
C.PLUGIN_VERSION           -- "BETA 0.9.4"
C.UI_CMD_ICON_NAME         -- "TimeMAricksIcon"
C.UI_MENU_NAME             -- "TimeMAtricks Menu"
C.UI_SETTINGS_NAME         -- "Settings Menu"
C.colors.text.white        -- "Global.Text"
C.colors.button.please     -- "Button.BackgroundPlease"
C.icons.matricks           -- "object_matricks"
C.corners.all              -- "corner15"
C.fade.min_size            -- 200
C.master_limits.timing.max -- 50
C.global_vars              -- Array of all TM_* variable names
```

### helpers.lua
```lua
H.get_global(var_name, default)
H.set_global(var_name, value)
H.sanitize_text(text)
H.validate_master_input(input, is_timing)
H.bpm_quartic(normed)
H.calculate_time_from_bpm(bpm)
H.get_ma_version()
H.get_subdir(subdir)
H.is_valid_ui_item(obj_name, subdir)
H.get_ui_item_index(obj_name, subdir)
H.write_text_file(path, content)
```

### state.lua
```lua
S.save_state(helpers, overlay)
S.load_state(helpers, overlay, plugin_running)
```

### ui_xml.lua
```lua
X.UI_XML_CONTENT           -- Main UI XML string
X.UI_XML_SETTINGS          -- Settings UI XML string
X.resolve_xml_file(helpers, xml_type)  -- Returns: dir, filename
```

### ui.lua
```lua
U.add_ui_element(name, overlay, element_type, options, my_handle)
U.fade_adjust(constants, helpers, direction, caller)
U.update_fade_buttons(constants, helpers, overlay)
U.create_cmd_line_icon(constants, my_handle)
U.delete_cmd_line_icon(constants)
U.create_panic_macro(constants)
U.create_menu(C, H, S, X, signal_table, my_handle, plugin_running)
U.create_settings_menu(C, H, S, X, signal_table, my_handle)
```

### matricks.lua
```lua
M.get_all_matricks()  -- Returns: mx_table, mx_path
M.validate_matricks_name(helpers, caller, caller_id, content)
M.rename_matricks_triplet(caller_id, new_name, prefix, mx_table, mx_path)
M.create_matricks_triplet(helpers, caller_id, new_name, prefix, mx_table, mx_path)
M.handle_prefix_change(helpers, caller, old_prefix, new_prefix)
M.handle_prefix_toggle(helpers, new_state, prefix)
M.matricks_handler(helpers, caller, show_warning_func)
M.apply_to_triplets(helpers, mx_pool, values, normed)
```

## 💡 Pro Tips

1. **Always inject dependencies** - Pass modules as parameters, don't create globals
2. **Use constants for magic values** - Add to constants.lua instead of hardcoding
3. **Test modules individually** - Each module can be loaded and tested separately
4. **Follow naming conventions** - snake_case everywhere except CONSTANTS
5. **Document as you go** - Add section headers and function comments
6. **Keep functions small** - If > 50 lines, consider splitting
7. **Return success/error** - Use `return false, "error msg"` pattern
8. **Save state frequently** - Call S.save_state() after user changes

---

**Need more details?** See `DEPLOYMENT_GUIDE.md` for complete documentation.
