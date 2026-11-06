-- Conservative, explicitly limited UTF-8 label-key policy; Lua 5.1 compatible.
local M = {}
local replacements = {
  [0xA0] = ' ', [0x202F] = ' ', [0x3000] = ' ',
  [0x2010] = '-', [0x2011] = '-', [0x2012] = '-',
  [0x2013] = '-', [0x2014] = '-', [0x2015] = '-',
  [0x2018] = "'", [0x2019] = "'"
}

function M.normalize(value)
  if type(value) ~= 'string' then return nil, 'label_must_be_string' end
  if #value > 4096 then return nil, 'label_exceeds_4096_bytes' end
  local out, i = {}, 1
  while i <= #value do
    local first = value:byte(i)
    local length, cp
    if first < 128 then length, cp = 1, first
    elseif first >= 194 and first <= 223 then length, cp = 2, first - 192
    elseif first >= 224 and first <= 239 then length, cp = 3, first - 224
    elseif first >= 240 and first <= 244 then length, cp = 4, first - 240
    else return nil, 'invalid_utf8' end
    if i + length - 1 > #value then return nil, 'invalid_utf8' end
    for j = 1, length - 1 do
      local b = value:byte(i + j)
      if b < 128 or b > 191 then return nil, 'invalid_utf8' end
      cp = cp * 64 + b - 128
    end
    if (length == 2 and cp < 128) or (length == 3 and cp < 2048) or
       (length == 4 and cp < 65536) or cp > 0x10FFFF or
       (cp >= 0xD800 and cp <= 0xDFFF) then return nil, 'invalid_utf8' end
    if (cp < 32 and cp ~= 9) or (cp >= 127 and cp <= 159) or
       cp == 0x2028 or cp == 0x2029 then return nil, 'control_character' end
    if (cp >= 0x202A and cp <= 0x202E) or (cp >= 0x2066 and cp <= 0x2069) then
      return nil, 'bidi_control'
    end
    if cp >= 65 and cp <= 90 then out[#out+1] = string.char(cp + 32)
    elseif cp == 9 then out[#out+1] = ' '
    else out[#out+1] = replacements[cp] or value:sub(i, i+length-1) end
    i = i + length
  end
  local key = table.concat(out):gsub(' +', ' '):gsub('^ ', ''):gsub(' $', '')
  if key == '' then return nil, 'empty_label' end
  return key
end

return M
