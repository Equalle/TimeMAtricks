O = {}

-- Convert speed master fader value (0-1 normalized) to BPM using quartic curve
function O.bpm_quartic(normed)
  -- Quartic polynomial coefficients (highest degree -> lowest)
  local a4 = 1.4782363954528236e-07
  local a3 = -4.7011506911898910e-05
  local a2 = 0.02546732094127444
  local a1 = 0.02565532641182032
  local a0 = -0.015923207227581285
  local y = ((((a4 * normed + a3) * normed + a2) * normed + a1) * normed + a0)
  if y <= 30 then y = 30 end
  if y >= 0 then
    return math.floor(y * 10 + 0.5) / 10
  else
    return math.ceil(y * 10 - 0.5) / 10
  end
end

-- Get normalized fader value from master (timing or speed)
-- Returns normalized value with proper scaling for the selected master type
function O.get_master_fader_normalized()
  local masterID = GMA.get_global(C.GVars.mvalue)
  if not masterID or masterID == "" then
    return nil
  end

  local mstr = MasterPool()
  local master = nil

  if GMA.get_global(C.GVars.timing) == 1 then
    -- Timing master (1-50 range)
    master = mstr.Timing:Ptr(tonumber(masterID))
    if not master then return nil end
    local normed = master:GetFader({}) or 0
    normed = normed / 10                          -- Timing master returns 0-1000, normalize to 0-100
    normed = math.floor(normed * 100 + 0.5) / 100 -- Round to 2 decimals
    return normed
  elseif GMA.get_global(C.GVars.speed) == 1 then
    -- Speed master (1-16 range)
    master = mstr.Speed:Ptr(tonumber(masterID))
    if not master then return nil end
    local normed = master:GetFader({}) or 0       -- Already 0-1 normalized
    local bpm = O.bpm_quartic(normed)
    normed = 60 / bpm                             -- Convert BPM to beats per second
    normed = math.floor(normed * 100 + 0.5) / 100 -- Round to 2 decimals
    return normed
  end

  return nil
end

-- Apply matricks triplet with fade and delay
-- baseName: string name of the matricks (e.g., "Test")
-- rate: number multiplier for timing (e.g., 0.25, 0.5, 1.0)
-- prefix: string prefix to prepend to matricks name (e.g., "PREFIX_")
-- fadeAmount: number between 0-1 indicating fade/delay split (0 = all delay, 1 = all fade)
-- timing: normalized timing value
function O.apply_matricks_triplet(baseName, rate, prefix, fadeAmount, timing)
  if not baseName or baseName == "" then
    Echo("DEBUG apply_matricks_triplet: baseName is empty")
    return
  end
  if not timing or timing == 0 then
    Echo("DEBUG apply_matricks_triplet: timing is invalid: " .. tostring(timing))
    return
  end

  local mxPool = DataPool(1).Matricks
  Echo("DEBUG apply_matricks_triplet: mxPool = " .. tostring(mxPool))

  local d = timing * rate -- Calculate total delay
  Echo("DEBUG apply_matricks_triplet: baseName=" ..
    tostring(baseName) .. ", rate=" .. tostring(rate) .. ", timing=" .. tostring(timing) .. ", d=" .. tostring(d))

  local fade, delay
  if fadeAmount and fadeAmount > 0 then
    fade = d * fadeAmount
    delay = d * (1 - fadeAmount)
  else
    fade = "None"
    delay = d
  end

  Echo("DEBUG apply_matricks_triplet: fade=" .. tostring(fade) .. ", delay=" .. tostring(delay))

  -- Apply to all three triplet objects
  for k = 1, 3 do
    local fullName = prefix .. baseName .. " " .. k
    Echo("DEBUG apply_matricks_triplet: Looking for triplet: " .. tostring(fullName))
    local obj = mxPool:Find(fullName)
    if obj then
      Echo("DEBUG apply_matricks_triplet: Found " ..
        fullName .. ", setting fade=" .. tostring(fade) .. ", delay=" .. tostring(delay))
      obj:Set("FadeFromX", fade)
      obj:Set("DelayFromX", delay)
      obj:Set("DelayToX", 0)
    else
      Echo("DEBUG apply_matricks_triplet: NOT FOUND: " .. fullName)
    end
  end
end

function O.master_limit(caller, value)
  local before = caller.Content
  local after = before

  after = after:gsub("[^%d]", "")

  if after ~= "" then
    local num = tonumber(after)
    if num then
      if GMA.get_global(C.GVars.timing) == 1 then
        if num < 1 then
          after = 1
        elseif num > 50 then
          after = 50
        end
      elseif GMA.get_global(C.GVars.speed) == 1 then
        if num < 1 then
          after = 1
        elseif num > 16 then
          after = 16
        end
      end
    end
    return after
  end
end

-- Matricks name field mappings: { element_name, gvar_name }
local MATRICKS_NAME_FIELDS = {
  { name = "Matricks Prefix Name", gvar = "prefixname" },
  { name = "Matricks 1 Name",      gvar = "mx1name" },
  { name = "Matricks 2 Name",      gvar = "mx2name" },
  { name = "Matricks 3 Name",      gvar = "mx3name" },
}

-- Save matricks name with duplicate checking
function O.save_matricks_name(caller, newName)
  if not caller or newName == "" then return end

  -- Find the current field's entry
  local currentField = nil
  for _, field in ipairs(MATRICKS_NAME_FIELDS) do
    if UI.find_element(field.name) == caller then
      currentField = field
      break
    end
  end

  if not currentField then return end

  -- Check for duplicates in other matricks names
  -- Only compare Matricks 1-3 with each other, never compare with prefix
  for _, field in ipairs(MATRICKS_NAME_FIELDS) do
    -- Skip if it's the current field or if either field is prefix
    if field ~= currentField and currentField.gvar ~= "prefixname" and field.gvar ~= "prefixname" then
      local existingName = GMA.get_global(C.GVars[field.gvar])
      if existingName and existingName == newName then
        -- Duplicate found - show warning and revert
        SignalTable.show_warning(caller, "Name already taken")
        caller.Content = GMA.get_global(C.GVars[currentField.gvar]) or ""
        FindBestFocus(caller)
        caller:SelectAll()
        return
      end
    end
  end

  -- No duplicate - save the name
  GMA.set_global(C.GVars[currentField.gvar], newName)
end

-- Handle master mode switching with validation
function O.set_master_mode(newMode)
  -- newMode: 1 for timing (1-50), 0 for speed (1-16)
  local currentValue = GMA.get_global(C.GVars.mvalue)

  if newMode == 1 then
    -- Switching to timing master (1-50)
    GMA.set_global(C.GVars.timing, 1)
    GMA.set_global(C.GVars.speed, 0)
  elseif newMode == 0 then
    -- Switching to speed master (1-16)
    -- Check if current value is valid for speed master
    if currentValue and tonumber(currentValue) > 16 then
      -- Value too high for speed master - clear it and show warning
      GMA.set_global(C.GVars.mvalue, nil)
      local masterIDElement = UI.find_element("Master ID")
      if masterIDElement then
        masterIDElement.Content = ""
      end
      SignalTable.show_warning(nil, "Set new master 1-16")
    end
    GMA.set_global(C.GVars.timing, 0)
    GMA.set_global(C.GVars.speed, 1)
  end
end

function O.sanitize_rate(text, caller)
  text = tostring(text or "")
  if text == "" then return "" end

  local originalText = text

  -- convert comma to dots
  text = text:gsub(",", ".")
  -- keep only digits and dot
  text = text:gsub("[^%d%.]", "")
  --keep just the first dot
  local fistDotSeen = false
  local cleaned = {}
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "." then
      if not fistDotSeen then
        table.insert(cleaned, c)
        fistDotSeen = true
      end
    else
      table.insert(cleaned, c)
    end
  end
  text = table.concat(cleaned)

  --msut start with a digit, find first digit
  local firstDigit = text:match("%d")
  if not firstDigit then
    return ""
  end

  -- build result
  local digitIndex = text:find(firstDigit, 1, true)
  local afterFirst = text:sub(digitIndex + 1)

  -- ignore any further digits before a possible dot
  local dotPos = afterFirst:find("%.")
  if dotPos then
    --there is a dot after the leading digit
    local decimals = afterFirst:sub(dotPos + 1)
    decimals = decimals:gsub("%.", "")              -- remove any further dots
    decimals = decimals:gsub("[^%d]", ""):sub(1, 2) -- keep only digits, max 2
    if decimals == "" and text:sub(-1) == "." then
      -- user just typed the dot; allow transient
      return firstDigit .. "."
    end
    local result = firstDigit .. "." .. decimals
    -- Check if there was a format error
    if result ~= originalText and originalText ~= "" then
      if caller then
        SignalTable.show_warning(caller, "Rate format: x.xx")
      end
    end
    return result
  else
    -- no dot, just return leading digits
    local result = firstDigit
    -- Check if there was a format error
    if result ~= originalText and originalText ~= "" then
      if caller then
        SignalTable.show_warning(caller, "Rate format: x.xx")
      end
    end
    return result
  end
end

-- Sanitize refresh rate: only allow numbers from 0.1 to 10 in x.x format
function O.sanitize_refresh(text, caller)
  text = tostring(text or "")
  if text == "" then return "" end

  local originalText = text

  -- convert comma to dots
  text = text:gsub(",", ".")
  -- keep only digits and dot
  text = text:gsub("[^%d%.]", "")
  -- keep just the first dot
  local firstDotSeen = false
  local cleaned = {}
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "." then
      if not firstDotSeen then
        table.insert(cleaned, c)
        firstDotSeen = true
      end
    else
      table.insert(cleaned, c)
    end
  end
  text = table.concat(cleaned)

  -- must start with a digit, find first digit
  local firstDigit = text:match("%d")
  if not firstDigit then
    return ""
  end

  -- build result
  local digitIndex = text:find(firstDigit, 1, true)
  local afterFirst = text:sub(digitIndex + 1)

  -- ignore any further digits before a possible dot
  local dotPos = afterFirst:find("%.")
  local result = ""
  if dotPos then
    -- there is a dot after the leading digit
    local decimals = afterFirst:sub(dotPos + 1)
    decimals = decimals:gsub("%.", "")              -- remove any further dots
    decimals = decimals:gsub("[^%d]", ""):sub(1, 1) -- keep only 1 decimal
    if decimals == "" and text:sub(-1) == "." then
      -- user just typed the dot; allow transient
      return firstDigit .. "."
    end
    result = firstDigit .. "." .. decimals
  else
    -- no dot, just return leading digit
    result = firstDigit
  end

  -- Check if there was a format error
  if result ~= originalText and originalText ~= "" then
    if caller then
      SignalTable.show_warning(caller, "Refresh format: x.x")
    end
  end

  return result
end

local function get_fade_dimensions()
  local menu = C.UI_MENU
  local menuwidth = tonumber(menu:Get("W")) or 600 -- Convert to number, default to 600
  local fullwidth = menuwidth - 50                 -- remove padding
  local center = fullwidth / 2
  local step = 70
  local min = center - (step * 2)
  local max = center + (step * 2)

  return center, step, min, max
end

-- Convert fadeamount (0.3-0.7) to slider position
function O.fade_amount_to_position(fadeamount)
  local center, step, min, max = get_fade_dimensions()

  if fadeamount <= 0.3 then
    return min
  elseif fadeamount <= 0.4 then
    return center - step
  elseif fadeamount <= 0.5 then
    return center
  elseif fadeamount <= 0.6 then
    return center + step
  else -- fadeamount >= 0.7
    return max
  end
end

-- Convert slider position to fadeamount (0.3-0.7)
function O.fade_position_to_amount(position)
  local center, step, min, max = get_fade_dimensions()

  if position <= min then
    return 0.3
  elseif position <= center - step then
    return 0.4
  elseif position <= center then
    return 0.5
  elseif position <= center + step then
    return 0.6
  else -- position >= max
    return 0.7
  end
end

-- Update button texts based on slider position
function O.fade_update_buttons(position)
  local center, step, min, max = get_fade_dimensions()

  if position <= min then
    UI.edit_element("FadeLess", { Enabled = "Yes", Text = "MIN" })
    UI.edit_element("FadeMore", { Enabled = "Yes", Text = "Fade More" })
  elseif position >= max then
    UI.edit_element("FadeMore", { Enabled = "Yes", Text = "MAX" })
    UI.edit_element("FadeLess", { Enabled = "Yes", Text = "Fade Less" })
  else
    UI.edit_element("FadeLess", { Enabled = "Yes", Text = "Fade Less" })
    UI.edit_element("FadeMore", { Enabled = "Yes", Text = "Fade More" })
  end
end

-- Adjust fade slider by direction (called on button press)
function O.fade_adjust(direction)
  local anchor = C.UI_MENU:FindRecursive("Fade Width")
  if not anchor then
    ErrEcho("Error: Fade Width anchor not found")
    return
  end

  -- Check if fade is disabled (toggle button is held)
  local fadeEnabled = GMA.get_global(C.GVars.fade)
  if fadeEnabled == false then
    -- Re-enable fade functionality
    GMA.set_global(C.GVars.fade, true)
    UI.edit_element("FadeLess", { Enabled = "Yes" })
    UI.edit_element("FadeMore", { Enabled = "Yes" })

    -- Update button texts based on current position
    local curr = tonumber(anchor.Size)
    O.fade_update_buttons(curr)

    -- Echo("Fade re-enabled")
    return
  end

  local center, step, min, max = get_fade_dimensions()
  local curr = tonumber(anchor.Size)

  -- Calculate new position
  local new = curr + (step * direction)

  -- Clamp to min/max
  if new <= min then
    new = min
  elseif new >= max then
    new = max
  end

  -- Update slider position
  anchor.Size = new

  -- Update button texts
  O.fade_update_buttons(new)

  -- Convert to fadeamount and save
  local fadeamount = O.fade_position_to_amount(new)
  GMA.set_global(C.GVars.fadeamount, fadeamount)

  -- Echo("Fade adjusted: position=" .. tostring(new) .. ", amount=" .. tostring(fadeamount))
end

-- Load saved fadeamount and position slider (called on menu open)
function O.fade_set_from_global()
  local fadeamount = GMA.get_global(C.GVars.fadeamount) or 0.5
  local fadeEnabledRaw = GMA.get_global(C.GVars.fade)
  -- Convert to boolean: nil or true = enabled (default), false = disabled
  local fadeEnabled = fadeEnabledRaw ~= false

  local anchor = C.UI_MENU:FindRecursive("Fade Width")
  if not anchor then
    ErrEcho("Error: Fade Width anchor not found")
    return
  end

  local fadeLess = C.UI_MENU:FindRecursive("FadeLess")
  local fadeMore = C.UI_MENU:FindRecursive("FadeMore")
  if not fadeLess or not fadeMore then
    Echo("Error: Fade buttons not found")
    return
  end

  local center, step, min, max = get_fade_dimensions()

  if fadeEnabled then
    -- Fade is enabled - load saved fadeamount position
    local position = O.fade_amount_to_position(fadeamount)
    anchor.Size = tonumber(position) or 300
    O.fade_update_buttons(position)
  else
    -- Fade is disabled - reset slider to center
    anchor.Size = center
    UI.edit_element("FadeLess", { Enabled = "No", Text = "DISABLED" })
    UI.edit_element("FadeMore", { Text = "(Hold to enable)" })
  end

  -- Echo("Fade loaded: position=" .. tostring(position) .. ", amount=" .. tostring(fadeamount) .. ", enabled=" .. tostring(fadeEnabled))
end

function O.adjust_rate(factor)
  local currentRate = GMA.get_global(C.GVars.ovrate) or 1
  local newRate = currentRate * factor
  if factor == 1 then
    newRate = 1
    return newRate
    -- Clamp between 0.125 and 8
  elseif newRate < 0.125 then
    newRate = 0.125
  elseif newRate > 8.0 then
    newRate = 8.0
  end
  if newRate >= 1 then
    newRate = math.floor(newRate)                     -- round to nearest integer
  else
    newRate = math.floor(newRate * 1000 + 0.5) / 1000 -- round to 3 decimal places
  end
  return newRate
end

-- Get all matricks from pool with metadata
function O.get_all_matricks()
  local mxpath = DataPool(1).Matricks
  local mxt = {}
  for i = 1, 10000 do
    local p = mxpath:Ptr(i)
    if p then
      mxt[i] = {
        index = i,
        note = p:Get("Note"),
        name = p:Get("Name")
      }
    end
  end
  return mxt, mxpath
end

-- Validate matricks name (check for duplicates and empty)
function O.validate_matricks_name(caller, callerid, content)
  -- Get all matricks names for this callerid (1, 2, or 3)
  local globals = {
    GMA.get_global(C.GVars.mx1name),
    GMA.get_global(C.GVars.mx2name),
    GMA.get_global(C.GVars.mx3name),
  }

  -- Check for duplicate names (exclude current field)
  for i, v in ipairs(globals) do
    if i ~= callerid and content == v then
      SignalTable.show_warning(caller, "Name already used")
      local oldValue = GMA.get_global(C.GVars["mx" .. callerid .. "name"]) or ""
      caller.Content = oldValue
      return false
    end
  end

  -- Check for empty name
  if content == "" then
    SignalTable.show_warning(caller, "Matricks name cannot be empty")
    local oldValue = GMA.get_global(C.GVars["mx" .. callerid .. "name"]) or ""
    caller.Content = oldValue
    return false
  end

  return true
end

-- Rename existing matricks triplet (all three objects)
function O.rename_matricks_triplet(callerid, newName, prefix, mxt, mxpath)
  local cand = {}

  -- Find existing matricks with correct notes
  for _, v in pairs(mxt) do
    for i = 1, 3 do
      if v.note == "TimeMatricks " .. callerid .. "." .. i then
        cand[i] = {
          index = v.index,
          name = v.name
        }
      end
    end
  end

  -- Rename all three matricks triplet objects
  for i = 1, 3 do
    local found = false
    -- Try to find in candidates first
    if cand[i] and cand[i].name ~= newName then
      local obj = mxpath:FindRecursive(cand[i].name)
      if obj then
        obj:Set("Name", tostring(prefix .. newName .. " " .. i))
        found = true
      end
    end
    -- If not found in candidates, search all matricks
    if not found then
      for _, v in pairs(mxt) do
        if v.note == ("TimeMatricks " .. callerid .. "." .. i) then
          local obj = mxpath:FindRecursive(v.name)
          if obj and v.name ~= newName then
            obj:Set("Name", tostring(prefix .. newName .. " " .. i))
          end
        end
      end
    end
  end
end

-- Create new matricks triplet (all three objects)
function O.create_matricks_triplet(callerid, newName, prefix, mxt, mxpath)
  for i = 1, 3 do
    local exists = false
    local targetName = tostring(prefix .. newName .. " " .. i)
    local targetNote = "TimeMatricks " .. callerid .. "." .. i

    -- Check if already exists
    for _, v in pairs(mxt) do
      local obj = mxpath:FindRecursive(v.name)
      local objname = obj and obj:Get("Name") or ""
      local objnote = obj and obj:Get("Note") or ""
      if objname == targetName or objnote == targetNote then
        exists = true
        break
      end
    end

    if not exists then
      -- Find first free slot from settings start index
      local startidx = tonumber(GMA.get_global(C.GVars.mxstart) or 1) or 1
      local freeidx = nil
      for n = startidx, 10000 do
        if not mxpath:Ptr(n) then
          freeidx = n
          break
        end
      end

      if not freeidx then
        return false, "No free Matricks slot found"
      end

      local newobj = mxpath:Create(freeidx)
      if not newobj then
        return false, "Failed to create new object"
      end

      newobj:Set("Name", prefix .. newName .. " " .. i)
      newobj:Set("Note", targetNote)
      newobj:Set("InvertStyle", "All")
    end
  end
  return true
end

-- Handle matricks value changes (rename or create triplet)
function O.handle_matricks_value_change(caller, callerid)
  local content = caller.Content or ""

  -- Validate the name
  if not O.validate_matricks_name(caller, callerid, content) then
    return
  end

  -- Get prefix
  local prefixEnabled = GMA.get_global(C.GVars.prefix) or 0
  local prefixName = GMA.get_global(C.GVars.prefixname) or ""
  local prefix = ""
  if tonumber(prefixEnabled) == 1 and prefixName ~= "" then
    prefix = tostring(prefixName)
  end

  -- Get all matricks
  local mxt, mxpath = O.get_all_matricks()

  -- Check if triplet exists
  local found_any = false
  for _, v in pairs(mxt) do
    for i = 1, 3 do
      if v.note == "TimeMatricks " .. callerid .. "." .. i then
        found_any = true
        break
      end
    end
    if found_any then break end
  end

  if found_any then
    -- Rename existing triplet
    O.rename_matricks_triplet(callerid, content, prefix, mxt, mxpath)
  else
    -- Create new triplet
    local success, error = O.create_matricks_triplet(callerid, content, prefix, mxt, mxpath)
    if not success then
      SignalTable.show_warning(caller, error)
      return
    end
  end
end

-- Handle prefix name changes (rename all matricks to use new prefix)
function O.handle_prefix_change(caller, oldPrefix, newPrefix)
  if newPrefix == "" then
    SignalTable.show_warning(caller, "Prefix cannot be empty")
    caller.Content = oldPrefix
    return
  end

  local mxt, mxpath = O.get_all_matricks()
  for i, v in pairs(mxt) do
    local name = v.name
    if name and name ~= "" then
      local obj = mxpath:FindRecursive(name)
      if obj then
        -- Check if this is a TimeMatricks object
        local note = obj:Get("Note")
        if note and note:match("^TimeMatricks") then
          -- Remove old prefix if present
          local strippedName = name
          if strippedName:sub(1, #oldPrefix) == oldPrefix then
            strippedName = strippedName:sub(#oldPrefix + 1)
          end
          obj:Set("Name", newPrefix .. strippedName)
        end
      end
    end
  end
end

-- Debug
function O.echo(message)
  Echo("OPERATORS READY!")
end

return O
