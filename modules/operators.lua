O = {}

function O.master_limit(caller, value)
  local before = caller.Content
  local after = before

  after = after:gsub("[^%d]", "")

  if after ~= "" then
    local num = tonumber(after)
    if num then
      if GMA.get_globalV(C.GVars.timing) == 1 then
        if num < 1 then
          after = 1
        elseif num > 50 then
          after = 50
        end
      elseif GMA.get_globalV(C.GVars.speed) == 1 then
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

function O.fade_adjust(caller, width, direction)
  Echo(caller.Name)
  Echo(width)
  Echo(direction)
end

function O.fade_button()
end

-- Debug
function O.echo(message)
  Echo("OPERATORS READY!")
end

return O
