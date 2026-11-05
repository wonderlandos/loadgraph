-- SPDX-License-Identifier: GPL-2.0-or-later
-- Desktop card: CPU and memory over the last six minutes (one bar every 10 s), the figure now and
-- the highest point of each, and the load average.
local BARS = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

-- Values 0..100 as a line of bars, oldest first; the line is padded to `width` on the left.
local function graph(values, width)
  local out = {}
  for i = 1, width - #values do out[i] = " " end
  for _, v in ipairs(values) do
    local k = math.floor(math.max(0, math.min(100, v)) / 100 * 7 + 0.5) + 1
    out[#out + 1] = BARS[k]
  end
  return table.concat(out)
end

local function push(list, v, keep)
  list[#list + 1] = v
  while #list > keep do table.remove(list, 1) end
end

local function percent(v) return string.format("%d%%", math.floor(v + 0.5)) end

-- One sample of `wol sys stats --json`: cpu %, memory %, the reading itself (nil, message on failure).
local function read()
  local ok, out = wol.run { "wol", "sys", "stats", "--json", timeout = 5 }
  if not ok then return nil, out end
  local v, e = wol.json.decode(out)
  if not v then return nil, e end
  local total = (v.memory and v.memory.total) or 0
  local used = (v.memory and v.memory.used) or 0
  local mem = total > 0 and used * 100 / total or 0
  return (v.cpu_percent or 0), mem, v
end

local KEEP = 36
local cpu, mem, err, last = {}, {}, nil, nil

local function top(list)
  local t = 0
  for _, v in ipairs(list) do if v > t then t = v end end
  return t
end

return wol.widget {
  refresh = 10,
  render = function()
    local c, m, v = read()
    if not c then err = m else
      err = nil
      push(cpu, c, KEEP); push(mem, m, KEEP); last = v
    end
    if #cpu == 0 then
      return wol.stack { spacing = 4,
        wol.label { "Load Graph", role = "title" },
        wol.label { err or "Reading...", role = "secondary" },
      }
    end
    local load = last and last.load
    local minutes = math.max(1, math.floor(#cpu * 10 / 60 + 0.5))
    return wol.stack { spacing = 8,
      wol.row { spacing = 8,
        wol.label { "CPU", role = "caption" }, wol.spacer(),
        wol.label { percent(cpu[#cpu]) .. "  (highest " .. percent(top(cpu)) .. ")", role = "caption" } },
      wol.label { graph(cpu, KEEP), role = "title" },
      wol.row { spacing = 8,
        wol.label { "Memory", role = "caption" }, wol.spacer(),
        wol.label { percent(mem[#mem]) .. "  (highest " .. percent(top(mem)) .. ")", role = "caption" } },
      wol.label { graph(mem, KEEP), role = "title" },
      wol.label { string.format("Last %d min", minutes) ..
        (load and string.format(", load %.2f", load.one or 0) or ""), role = "secondary" },
    }
  end,
}
