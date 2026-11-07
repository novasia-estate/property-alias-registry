local normalize = require('property_alias.key').normalize
local M = {}
local function copy(entry)
  return {entity_id=entry.entity_id, alias=entry.alias, scope=entry.scope,
    provenance=entry.provenance, key=entry.key}
end
local function array_length(value)
  if type(value) ~= 'table' then error('entries must be an array', 3) end
  local n, count = #value, 0
  for k in pairs(value) do
    if type(k) ~= 'number' or k < 1 or k > n or k ~= math.floor(k) then
      error('entries must be a dense array', 3)
    end
    count = count + 1
  end
  if count ~= n then error('entries must be a dense array', 3) end
  if n > 10000 then error('at most 10000 aliases per registry', 3) end
  return n
end
local function plain(value, name, limit)
  if type(value) ~= 'string' or #value > limit or not value:match('%S') then
    error(name .. ' must be a bounded nonempty string', 3)
  end
  local valid, err = normalize(value)
  if not valid then error(name .. ': ' .. err, 3) end
  return value:match('^%s*(.-)%s*$')
end
local function ids(entries)
  local seen, out = {}, {}
  for _, e in ipairs(entries) do
    if not seen[e.entity_id] then seen[e.entity_id]=true; out[#out+1]=e.entity_id end
  end
  table.sort(out)
  return out
end

function M.new(input)
  local count = array_length(input)
  local entries, by_key = {}, {}
  for i=1,count do
    local e = input[i]
    if type(e) ~= 'table' then error('alias entry must be a table') end
    local key, err = normalize(e.alias)
    if not key then error('alias entry ' .. i .. ': ' .. err) end
    local stored = {entity_id=plain(e.entity_id,'entity_id',256),
      alias=e.alias, scope=plain(e.scope,'scope',256),
      provenance=plain(e.provenance,'provenance',2048), key=key}
    entries[#entries+1] = stored
    by_key[key] = by_key[key] or {}
    by_key[key][#by_key[key]+1] = stored
  end
  local api = {}

  function api:resolve(label, scope)
    local key, err = normalize(label)
    if not key then return {status='invalid', query=label, error=err, candidates={}, matches={}} end
    if scope ~= nil then
      local ok, value = pcall(plain, scope, 'scope', 256)
      if not ok then return {status='invalid',query=label,error='invalid_scope',candidates={},matches={}} end
      scope = value
    end
    local found = {}
    for _,e in ipairs(by_key[key] or {}) do
      if scope == nil or e.scope == scope then found[#found+1]=e end
    end
    local candidates = ids(found)
    local matches = {}
    for i,e in ipairs(found) do matches[i]=copy(e) end
    local status = #candidates == 0 and 'unknown' or #candidates == 1 and 'resolved' or 'ambiguous'
    return {status=status,query=label,key=key,scope=scope,candidates=candidates,
      matches=matches,entity_id=status == 'resolved' and candidates[1] or nil}
  end

  function api:entries()
    local out = {}
    for i,e in ipairs(entries) do out[i]=copy(e) end
    return out
  end

  function api:with(extra)
    array_length(extra)
    local combined = self:entries()
    for _,e in ipairs(extra) do combined[#combined+1]=e end
    return M.new(combined)
  end

  function api:without(selectors)
    -- Match complete authored observations, not just normalized alias keys.
    local checked = M.new(selectors):entries()
    local function identity(e)
      local out = {}
      for _, value in ipairs({e.entity_id,e.alias,e.scope,e.provenance}) do
        out[#out+1] = #value .. ':' .. value
      end
      return table.concat(out)
    end
    local selected, matched = {}, {}
    for _, e in ipairs(checked) do
      local key = identity(e)
      if selected[key] then error('withdrawal selectors must be distinct') end
      selected[key] = true
    end
    local retained, removed = {}, 0
    for _, e in ipairs(entries) do
      local key = identity(e)
      if selected[key] then removed=removed+1;matched[key]=true
      else retained[#retained+1]=copy(e) end
    end
    local unmatched, matched_count = {}, 0
    for _, e in ipairs(checked) do
      if matched[identity(e)] then matched_count=matched_count+1
      else unmatched[#unmatched+1]=copy(e) end
    end
    return M.new(retained), {requested_count=#checked,matched_selectors=matched_count,
      removed_count=removed,unmatched_entries=unmatched}
  end

  function api:audit()
    local scoped, unscoped, keys = {}, {}, {}
    for key in pairs(by_key) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
      local all = by_key[key]
      local all_ids = ids(all)
      if #all_ids > 1 then unscoped[#unscoped+1]={key=key,candidates=all_ids} end
      local scopes, scope_keys = {}, {}
      for _,e in ipairs(all) do
        if not scopes[e.scope] then scopes[e.scope]={};scope_keys[#scope_keys+1]=e.scope end
        local group=scopes[e.scope];group[#group+1]=e
      end
      table.sort(scope_keys)
      for _,scope in ipairs(scope_keys) do
        local candidates=ids(scopes[scope])
        if #candidates>1 then scoped[#scoped+1]={key=key,scope=scope,candidates=candidates} end
      end
    end
    return {entry_count=#entries,scoped_conflicts=scoped,unscoped_ambiguities=unscoped}
  end
  return api
end

return M
