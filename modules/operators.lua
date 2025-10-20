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

function O.sanitize_rate(text)
  text = tostring(text or "")
  if text == "" then return "" end
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
    return firstDigit .. "." .. decimals
  else
    -- no dot, just return leading digits
    return firstDigit
  end
end

-- Helper: Get fade slider dimensions
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

  -- Convert fadeamount to position
  local position = O.fade_amount_to_position(fadeamount)

  -- Set slider position (ensure it's a number)
  anchor.Size = tonumber(position) or 300

  -- First, always set the button texts based on position (enabled state)
  O.fade_update_buttons(position)

  -- Then, if fade is disabled, override with disabled texts and state
  if not fadeEnabled then
    fadeLess.Enabled = "No"
    fadeLess.Text = "DISABLED"
    fadeMore.Text = "(Press to enable)"
  end

  -- Echo("Fade loaded: position=" .. tostring(position) .. ", amount=" .. tostring(fadeamount) .. ", enabled=" .. tostring(fadeEnabled))
end

-- Debug
function O.echo(message)
  Echo("OPERATORS READY!")
end

return O
