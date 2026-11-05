-- SPDX-License-Identifier: GPL-2.0-or-later
-- Menu bar item: "CPU ▂▃▅▇▅▃ 41%", the last 30 s (one bar every 5 s). The popover gives CPU and
-- memory with their highest points and opens Top.
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

local KEEP = 6
local cpu, mem, err, last = {}, {}, nil, nil

local function top(list)
  local t = 0
  for _, v in ipairs(list) do if v > t then t = v end end
  return t
end

return wol.menubar {
  refresh = 5,
  render = function()
    local c, m, v = read()
    if not c then err = m else
      err = nil
      push(cpu, c, KEEP); push(mem, m, KEEP); last = v
    end
    if #cpu == 0 then return wol.label { "CPU -" } end
    return wol.label { "CPU " .. graph(cpu, KEEP) .. " " .. percent(cpu[#cpu]) }
  end,
  popover = function()
    local rows = {}
    if #cpu > 0 then
      rows[#rows + 1] = wol.item { title = "CPU " .. percent(cpu[#cpu]),
        subtitle = graph(cpu, KEEP) .. "  highest " .. percent(top(cpu)), icon = "utilities-system-monitor-symbolic" }
      rows[#rows + 1] = wol.item { title = "Memory " .. percent(mem[#mem]),
        subtitle = graph(mem, KEEP) .. "  highest " .. percent(top(mem)), icon = "drive-harddisk-symbolic" }
    end
    local load = last and last.load
    return wol.stack { spacing = 8,
      wol.label { "Load Graph", role = "title" },
      wol.label { err or (load and string.format("Load average %.2f, %.2f, %.2f", load.one or 0, load.five or 0, load.fifteen or 0)) or "The last 30 seconds", role = "secondary" },
      wol.list(rows),
      wol.button { label = "Open Top", on_click = function() wol.run { "foot", "-e", "btop" } end },
    }
  end,
}
