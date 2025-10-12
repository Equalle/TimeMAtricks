-- ---------------------------------------------------------------------------
-- MODULE: helpers
-- PURPOSE: Utility functions - globals, text processing, math, MA3 API
-- ---------------------------------------------------------------------------

local M = {}


-- ---------------------------------------------------------------------------
-- GLOBAL VARIABLE MANAGEMENT
-- ---------------------------------------------------------------------------

-- Get a global variable with optional default value
function M.get_global(var_name, default)
  return GetVar(GlobalVars(), var_name) or default
end


-- Set a global variable
function M.set_global(var_name, value)
  SetVar(GlobalVars(), var_name, value)
  return value ~= nil
end


-- ---------------------------------------------------------------------------
-- TEXT PROCESSING
-- ---------------------------------------------------------------------------

-- Sanitize numeric input (allow only one decimal point and up to 2 decimals)
function M.sanitize_text(text)
  text = tostring(text or "")
  if text == "" then return "" end
  
  -- Convert comma to dots
  text = text:gsub(",", ".")
  
  -- Keep only digits and dot
  text = text:gsub("[^%d%.]", "")
  
  -- Keep just the first dot
  local first_dot_seen = false
  local cleaned = {}
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "." then
      if not first_dot_seen then
        table.insert(cleaned, c)
        first_dot_seen = true
      end
    else
      table.insert(cleaned, c)
    end
  end
  text = table.concat(cleaned)
  
  -- Must start with a digit, find first digit
  local first_digit = text:match("%d")
  if not first_digit then
    return ""
  end
  
  -- Build result
  local digit_index = text:find(first_digit, 1, true)
  local after_first = text:sub(digit_index + 1)
  
  -- Find dot position
  local dot_pos = after_first:find("%.")
  if dot_pos then
    -- There is a dot after the leading digit
    local decimals = after_first:sub(dot_pos + 1)
    decimals = decimals:gsub("%.", "")              -- Remove any further dots
    decimals = decimals:gsub("[^%d]", ""):sub(1, 2) -- Keep only digits, max 2
    
    if decimals == "" and text:sub(-1) == "." then
      -- User just typed the dot; allow transient
      return first_digit .. "."
    end
    return first_digit .. "." .. decimals
  else
    -- No dot, just return leading digit
    return first_digit
  end
end


-- Validate master input based on type
function M.validate_master_input(input, is_timing)
  if input == "" then return "" end
  
  local num = tonumber(input)
  if not num then return input end
  
  if is_timing then
    if num < 1 then num = 1 elseif num > 50 then num = 50 end
  else
    if num < 1 then num = 1 elseif num > 16 then num = 16 end
  end
  
  return tostring(num)
end


-- ---------------------------------------------------------------------------
-- MATH FUNCTIONS
-- ---------------------------------------------------------------------------

-- Convert normalized speed master value to BPM using quartic polynomial
function M.bpm_quartic(normed)
  -- Coefficients (highest -> lowest): a4, a3, a2, a1, a0
  local a4 = 1.4782363954528236e-07
  local a3 = -4.7011506911898910e-05
  local a2 = 0.02546732094127444
  local a1 = 0.02565532641182032
  local a0 = -0.015923207227581285
  
  local y = ((((a4 * normed + a3) * normed + a2) * normed + a1) * normed + a0)
  
  -- Clamp to minimum
  if y <= 30 then y = 30 end
  
  -- Round to 1 decimal place
  if y >= 0 then
    return math.floor(y * 10 + 0.5) / 10
  else
    return math.ceil(y * 10 - 0.5) / 10
  end
end


-- Calculate time from BPM
function M.calculate_time_from_bpm(bpm)
  return 60 / bpm
end


-- ---------------------------------------------------------------------------
-- MA3 API UTILITIES
-- ---------------------------------------------------------------------------

-- Get MA version information
function M.get_ma_version()
  local text, major, minor, streaming, ui = Version()
  return text, major, minor, streaming, ui
end


-- Get subdirectory by name ("CmdLineSection" or "ScreenOverlay")
function M.get_subdir(subdir)
  return (subdir == "CmdLineSection" and GetDisplayByIndex(1).CmdLineSection)
      or (subdir == "ScreenOverlay" and GetDisplayByIndex(1).ScreenOverlay)
end


-- Check if UI item exists
function M.is_valid_ui_item(obj_name, subdir)
  local dir = M.get_subdir(subdir)
  if not dir then
    ErrPrintf("subdir not recognized: %s", tostring(subdir))
    return false
  end
  local found = dir:FindRecursive(obj_name)
  return found ~= nil
end


-- Get UI item index
function M.get_ui_item_index(obj_name, subdir)
  local dir = M.get_subdir(subdir)
  if not dir then return false end
  
  for i = 1, dir:Count() do
    if dir:Ptr(i).Name == obj_name then
      return i
    end
  end
  return false
end


-- ---------------------------------------------------------------------------
-- FILE OPERATIONS
-- ---------------------------------------------------------------------------

-- Write text file (overwrites only if content differs)
function M.write_text_file(path, content)
  local old = ""
  local f = io.open(path, "rb")
  if f then
    old = f:read("*a") or ""
    f:close()
  end
  
  if old == content then return true end
  
  local wf, err = io.open(path, "wb")
  if not wf then
    ErrPrintf("Failed to write %s: %s", tostring(path), tostring(err))
    return false
  end
  
  wf:write(content)
  wf:close()
  return true
end


return M
