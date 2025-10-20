O = {}

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

-- Debug
function O.echo(message)
  Echo("OPERATORS READY!")
end

return O
