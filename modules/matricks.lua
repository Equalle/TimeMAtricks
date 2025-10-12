-- ---------------------------------------------------------------------------
-- MODULE: matricks
-- PURPOSE: MAtricks business logic - creation, validation, management
-- ---------------------------------------------------------------------------

local M = {}


-- ---------------------------------------------------------------------------
-- MATRICKS COLLECTION
-- ---------------------------------------------------------------------------

-- Collect all matricks from the pool
function M.get_all_matricks()
  local mx_path = DataPool(1).Matricks
  local mx_table = {}
  
  for i = 1, 10000 do
    local p = mx_path:Ptr(i)
    if p then
      mx_table[i] = {
        index = i,
        note = p:Get("Note"),
        name = p:Get("Name")
      }
    end
  end
  
  return mx_table, mx_path
end


-- ---------------------------------------------------------------------------
-- VALIDATION
-- ---------------------------------------------------------------------------

-- Validate matricks name (check for duplicates and empty strings)
function M.validate_matricks_name(helpers, caller, caller_id, content)
  local globals = {
    helpers.get_global("TM_Matricks1Value"),
    helpers.get_global("TM_Matricks2Value"),
    helpers.get_global("TM_Matricks3Value"),
  }
  
  -- Check for duplicate names
  for i, v in ipairs(globals) do
    if i ~= caller_id and content == globals[i] then
      -- ShowWarning will be called from main file
      return false, "Name already used"
    end
  end
  
  -- Check for empty name
  if content == "" then
    return false, "Matricks name can not be empty"
  end
  
  return true
end


-- ---------------------------------------------------------------------------
-- TRIPLET MANAGEMENT
-- ---------------------------------------------------------------------------

-- Rename existing matricks triplet
function M.rename_matricks_triplet(caller_id, new_name, prefix, mx_table, mx_path)
  local cand = {}
  
  -- Find existing matricks with correct notes
  for _, v in pairs(mx_table) do
    for i = 1, 3 do
      if v.note == "TimeMatricks " .. caller_id .. "." .. i then
        cand[i] = {
          index = v.index,
          name = v.name
        }
      end
    end
  end
  
  -- Rename all three matricks
  for i = 1, 3 do
    local found = false
    
    -- Try to find in candidates first
    if cand[i] and cand[i].name ~= new_name then
      local obj = mx_path:FindRecursive(cand[i].name)
      if obj then
        obj:Set("Name", tostring(prefix .. new_name .. " " .. i))
        found = true
      end
    end
    
    -- If not found in candidates, search all matricks
    if not found then
      for _, v in pairs(mx_table) do
        if v.note == ("TimeMatricks " .. caller_id .. "." .. i) then
          local obj = mx_path:FindRecursive(v.name)
          if obj and v.name ~= new_name then
            obj:Set("Name", tostring(prefix .. new_name .. " " .. i))
          end
        end
      end
    end
  end
end


-- Create new matricks triplet
function M.create_matricks_triplet(helpers, caller_id, new_name, prefix, mx_table, mx_path)
  for i = 1, 3 do
    local exists = false
    local target_name = tostring(prefix .. new_name .. " " .. i)
    local target_note = "TimeMatricks " .. caller_id .. "." .. i
    
    -- Check if already exists
    for _, v in pairs(mx_table) do
      local obj = mx_path:FindRecursive(v.name)
      local obj_name = obj and obj:Get("Name") or ""
      local obj_note = obj and obj:Get("Note") or ""
      
      if obj_name == target_name or obj_note == target_note then
        exists = true
        break
      end
    end
    
    if not exists then
      -- Find first free slot
      local start_idx = tonumber(helpers.get_global("TM_MatricksStartIndex", "1")) or 1
      local free_idx = nil
      
      for n = start_idx, 10000 do
        if not mx_path:Ptr(n) then
          free_idx = n
          break
        end
      end
      
      if not free_idx then
        return false, "No free Matricks slot found"
      end
      
      local new_obj = mx_path:Create(free_idx)
      if not new_obj then
        return false, "Failed to create new object"
      end
      
      new_obj:Set("Name", prefix .. new_name .. " " .. i)
      new_obj:Set("Note", target_note)
      new_obj:Set("InvertStyle", "All")
    end
  end
  
  return true
end


-- ---------------------------------------------------------------------------
-- PREFIX MANAGEMENT
-- ---------------------------------------------------------------------------

-- Handle prefix value changes
function M.handle_prefix_change(helpers, caller, old_prefix, new_prefix)
  if new_prefix == "" then
    return false, "Prefix can not be empty"
  end
  
  local mx_table, mx_path = M.get_all_matricks()
  
  for i, v in ipairs(mx_table) do
    local name = v.name
    if name and name ~= "" then
      local obj = mx_path:FindRecursive(name)
      if obj then
        -- Remove old prefix if present
        local stripped_name = name
        if stripped_name:sub(1, #old_prefix) == old_prefix then
          stripped_name = stripped_name:sub(#old_prefix + 1)
        end
        obj:Set("Name", new_prefix .. stripped_name)
      end
    end
  end
  
  return true
end


-- Handle prefix toggle (add/remove prefix from existing triplets)
function M.handle_prefix_toggle(helpers, new_state, prefix)
  if prefix == "" then
    return
  end
  
  local matricks_pool = DataPool(1).Matricks
  local target_notes = {
    ["TimeMatricks 1.1"] = true,
    ["TimeMatricks 1.2"] = true,
    ["TimeMatricks 1.3"] = true,
    ["TimeMatricks 2.1"] = true,
    ["TimeMatricks 2.2"] = true,
    ["TimeMatricks 2.3"] = true,
    ["TimeMatricks 3.1"] = true,
    ["TimeMatricks 3.2"] = true,
    ["TimeMatricks 3.3"] = true,
  }
  
  for i = 1, 10000 do
    local obj = matricks_pool:Ptr(i)
    
    if obj then
      local note = obj:Get("Note")
      if note and target_notes[note] then
        local name = obj:Get("Name") or ""
        
        if new_state == 0 then
          -- Remove prefix if present
          if name:sub(1, #prefix) == prefix then
            local stripped = name:sub(#prefix + 1)
            if stripped ~= "" then
              obj:Set("Name", stripped)
            end
          end
        else
          -- Add prefix if missing
          if name:sub(1, #prefix) ~= prefix then
            obj:Set("Name", prefix .. name)
          end
        end
      end
    end
  end
end


-- ---------------------------------------------------------------------------
-- MAIN HANDLER
-- ---------------------------------------------------------------------------

-- Main matricks handler for value changes
function M.matricks_handler(helpers, caller, show_warning_func)
  if not caller then return end
  local c_name = caller.Name or ""
  
  local prefix_toggle = (tonumber(helpers.get_global("TM_MatricksPrefixButton", 0)) or 1)
  local old_prefix = helpers.get_global("TM_MatricksPrefixValue", "") or ""
  
  if c_name == "MatricksPrefixValue" then
    local new_prefix = caller.Content or ""
    if prefix_toggle == 1 and new_prefix ~= old_prefix then
      local success, error_msg = M.handle_prefix_change(helpers, caller, old_prefix, new_prefix)
      if not success then
        show_warning_func(caller, error_msg)
        caller:Set("Content", old_prefix)
      end
    end
  elseif c_name == "Matricks1Value" or c_name == "Matricks2Value" or c_name == "Matricks3Value" then
    local caller_id
    if c_name == "Matricks1Value" then
      caller_id = 1
    elseif c_name == "Matricks2Value" then
      caller_id = 2
    elseif c_name == "Matricks3Value" then
      caller_id = 3
    else
      return
    end
    
    local content = caller.Content or ""
    
    -- Validate the name
    local valid, error_msg = M.validate_matricks_name(helpers, caller, caller_id, content)
    if not valid then
      show_warning_func(caller, error_msg)
      local old_value = helpers.get_global("TM_Matricks" .. caller_id .. "Value", "")
      caller:Set("Content", old_value)
      return
    end
    
    -- Get prefix
    local prefix = ""
    if prefix_toggle == 1 and old_prefix ~= "" then
      prefix = tostring(old_prefix)
    end
    
    -- Get all matricks
    local mx_table, mx_path = M.get_all_matricks()
    
    -- Check if triplet exists
    local found_any = false
    for _, v in pairs(mx_table) do
      for i = 1, 3 do
        if v.note == "TimeMatricks " .. caller_id .. "." .. i then
          found_any = true
          break
        end
      end
      if found_any then break end
    end
    
    if found_any then
      -- Rename existing triplet
      M.rename_matricks_triplet(caller_id, content, prefix, mx_table, mx_path)
    else
      -- Create new triplet
      local success, error = M.create_matricks_triplet(helpers, caller_id, content, prefix, mx_table, mx_path)
      if not success then
        show_warning_func(caller, error)
        return
      end
    end
  end
end


-- ---------------------------------------------------------------------------
-- PLUGIN LOOP APPLICATION
-- ---------------------------------------------------------------------------

-- Apply calculated time to matricks triplets
function M.apply_to_triplets(helpers, mx_pool, values, normed)
  -- Helper to apply rate to a triplet (k=1..3)
  local function apply_triplet(base_name, rate)
    if base_name == "" then return end
    
    local use_prefix = (tonumber(values.mpt) == 1) and (values.mpv ~= "")
    local prefix = use_prefix and values.mpv or ""
    local d = normed * rate
    
    -- Split d into fade and delay
    local fade, delay
    if tonumber(values.ft) == 0 then
      fade = "None"
      delay = d
    else
      fade = d * tonumber(values.fv)
      delay = d * (1 - tonumber(values.fv))
    end
    
    for k = 1, 3 do
      local full_name = prefix .. base_name .. " " .. k
      local obj = mx_pool:Find(full_name)
      if obj then
        obj:Set("FadeFromX", fade)
        obj:Set("DelayFromX", delay)
        obj:Set("DelayToX", 0)
      end
    end
  end
  
  if values.m1t == 1 then apply_triplet(values.m1v, tonumber(values.m1r) or 0.25) end
  if values.m2t == 1 then apply_triplet(values.m2v, tonumber(values.m2r) or 0.5) end
  if values.m3t == 1 then apply_triplet(values.m3v, tonumber(values.m3r) or 1.0) end
end


return M
