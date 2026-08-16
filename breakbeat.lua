-- breakbeat
-- four-lane breakbeat trigger sequencer for norns + crow
-- v1.2.0

local arc_source = arc
local grid_source = grid
local toga_enabled = util.file_exists(_path.code .. "toga/lib/togaarc.lua")
if toga_enabled then
  arc_source = include "toga/lib/togaarc"
  grid_source = include "toga/lib/togagrid"
end

local patterns = {
  { name = "Straight Break", kick = "x.....x.x....x..", snare = "....x.......x...", hat = "x.x.x.x.x.x.x.x.", perc = "...x.....x....x." },
  { name = "Funky Break",   kick = "x.....x.x.x.....", snare = "....x.......x...", hat = "x.x.x.xx.x.xxxxx", perc = "...x.....x....x." },
  { name = "Amen-ish",      kick = "x.....x.x....x..", snare = "....x.....x.x...", hat = "x.x.x.x.x.x.x.xx", perc = "...x.....x....x." },
  { name = "Chopped Amen",  kick = "x....x....x.x...", snare = "....x..x....x...", hat = "xx.xxx.xxx.xxxxx", perc = "..x....x.x....x." },
  { name = "Jungle",        kick = "x.....x..x..x...", snare = "....x.....x.x...", hat = "xxxxx.xxxxxxx.xx", perc = "...x.x.....x..x." },
  { name = "Sparse Jungle", kick = "x.........x..x..", snare = "....x.......x...", hat = "x.x...x.x.x..x.x", perc = "...x.....x......" },
  { name = "Broken Beat",   kick = "x....x.....x..x.", snare = "....x..x....x...", hat = "x.xx.x.x.xx.x.x.", perc = "..x......x...x.." },
  { name = "Two Step",      kick = "x.......x..x....", snare = "....x.......x...", hat = "x.x.x.x.x.x.x.xx", perc = "......x......x.." },
  { name = "Steppy",        kick = "x..x...x..x..x..", snare = "....x.......x...", hat = "xxxxxxx.xxxxxxxx", perc = "..x...x....x..x." },
  { name = "Half-time",     kick = "x.....x...x.....", snare = "........x.......", hat = "x.x.x.x.x.x.x.x.", perc = "...x.......x..x." },
  { name = "Syncopated",    kick = "x....x.x...x..x.", snare = "....x.......x..x", hat = "x.xx.x.xxx.x.x.x", perc = "..x......x.x...." },
  { name = "Ruff Break",    kick = "x.....x.x..x..x.", snare = "...xx......xx...", hat = "xxx.x.x.xxx.xxxx", perc = "..x....x..x....x" },
  { name = "Think Break",   kick = "x..x....x.x...x.", snare = "....x.......x...", hat = "x.xxx.x.x.xxx.xx", perc = "..x....x...x...x" },
  { name = "Hot Pants",     kick = "x....x..x.....x.", snare = "....x.......x...", hat = "x.xx.xxxx.xx.xxx", perc = "...x..x....x..x." },
  { name = "Apache",        kick = "x.....x.x..x....", snare = "....x.......x...", hat = "x.xxxx.x.xxxx.x.", perc = "...x...x..x...x." },
  { name = "Funky Drummer", kick = "x..x..x...x..x..", snare = "....x.......x...", hat = "xxxxxx.xxxxxxx.x", perc = "..x....x...x..x." },
  { name = "Soul Pride",    kick = "x....x.x..x....x", snare = "....x.......x...", hat = "x.xxxx.xxx.xxx.x", perc = "...x..x....x.x.." },
  { name = "Cold Sweat",    kick = "x..x....x....x..", snare = "....x.......x...", hat = "xxxx.xxxxxxx.xxx", perc = "..x....x..x....x" },
  { name = "DnB Roller",    kick = "x.....x..x....x.", snare = "....x.....x.x...", hat = "xxxxxxxxxxxxxxxx", perc = "...x...x...x...x" },
  { name = "Jungle Rush",   kick = "x...x....x..x...", snare = "....x..x..x.x...", hat = "xxx.xxxxxxx.xxxx", perc = "..x...x....x..x." },
  { name = "Neuro Step",    kick = "x......xx..x....", snare = "....x.......x...", hat = "x.xx..xxx.xx..xx", perc = "..x..x....x..x.." },
  { name = "Garage Swing",  kick = "x.......x....x..", snare = "....x.......x...", hat = "x.xx.x.xx.xx.x.x", perc = "...x..x....x..x." },
  { name = "Footwork",      kick = "x..x..x.x..x..x.", snare = "....x.......x...", hat = "x.x.x.x.x.x.x.x.", perc = ".x...x...x...x.." },
  { name = "Glitch Break",  kick = "x.x....x..x.x...", snare = "...xx.....x.x..x", hat = "xx.xxxx.xx.xxxxx", perc = ".x....xx...x..x." }
}

local lane_keys = { "kick", "snare", "hat", "perc" }
local lane_names = { "K", "S", "H", "P" }
local pattern_index = 1
local mutation_base = 0
local mutation_cv = 0
local mutation = 0
local gate_probability = 100
local chaos = 0
local loop_length = 16
local position = 0
local playing = true
local sequence_clock = nil
local current = {}
local arc_device = nil
local grid_device = nil
local edited_patterns = {}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

local function authored_pattern(index)
  local rows = {}
  local source = patterns[index]

  for lane = 1, 4 do
    rows[lane] = {}
    local text = source[lane_keys[lane]]
    for step = 1, 16 do
      rows[lane][step] = text:sub(step, step) == "x"
    end
  end
  return rows
end

local function editable_pattern()
  if not edited_patterns[pattern_index] then
    edited_patterns[pattern_index] = authored_pattern(pattern_index)
  end
  return edited_patterns[pattern_index]
end

local function copy_pattern()
  local source = editable_pattern()
  current = {}

  for lane = 1, 4 do
    current[lane] = {}
    for step = 1, 16 do current[lane][step] = source[lane][step] end
  end
end

local function update_mutation()
  mutation = clamp(mutation_base + mutation_cv, 0, 100)
end

local function rotate_row(row, amount)
  local rotated = {}
  for step = 1, 16 do
    rotated[step] = row[((step - amount - 1) % 16) + 1]
  end
  return rotated
end

local function reverse_row(row)
  local reversed = {}
  for step = 1, 16 do reversed[step] = row[17 - step] end
  return reversed
end

local function make_variation()
  copy_pattern()
  if mutation > 0 then
    -- At maximum, each cell has a 30% chance of changing state.
    local chance = (mutation / 100) * 0.30
    for lane = 1, 4 do
      for step = 1, 16 do
        if math.random() < chance then
          current[lane][step] = not current[lane][step]
        end
      end
    end
  end


  -- Chaos makes bar-stable timing transformations, separate from mutation.
  if chaos > 0 then
    local max_shift = math.max(1, math.floor(chaos / 25))
    for lane = 1, 4 do
      if math.random(100) <= chaos then
        current[lane] = rotate_row(current[lane], math.random(-max_shift, max_shift))
      end
      if math.random(200) <= chaos then
        current[lane] = reverse_row(current[lane])
      end
    end
  end
end

local function reset_pattern()
  edited_patterns[pattern_index] = authored_pattern(pattern_index)
  position = 0
  make_variation()
  redraw()
end

local function toggle_step(lane, step)
  local pattern = editable_pattern()
  pattern[lane][step] = not pattern[lane][step]
  make_variation()
  redraw()
end

local function grid_redraw()
  if not grid_device then return end
  local pattern = editable_pattern()
  grid_device:all(0)

  for lane = 1, 4 do
    for step = 1, 16 do
      local level = pattern[lane][step] and 12 or 1
      if step > loop_length then level = pattern[lane][step] and 4 or 0 end
      if playing and step == position then level = pattern[lane][step] and 15 or 6 end
      grid_device:led(step, lane, level)
    end
  end

  -- Bottom-right button restores the selected pattern's authored version.
  grid_device:led(16, 8, 10)
  grid_device:refresh()
end

local function setup_grid()
  grid_device = grid_source.connect()
  if not grid_device then return end

  grid_device.key = function(x, y, z)
    if z == 0 then return end
    if y >= 1 and y <= 4 and x >= 1 and x <= 16 then
      toggle_step(y, x)
      grid_redraw()
    elseif x == 16 and y == 8 then
      reset_pattern()
      grid_redraw()
    end
  end
  grid_redraw()
end

local function trigger_step(step)
  for lane = 1, 4 do
    if current[lane][step] and math.random(100) <= gate_probability then
      crow.output[lane]()
    end
  end
end

local function sequence_loop()
  while true do
    if playing then
      clock.sync(1 / 4)
      position = (position % loop_length) + 1
      if position == 1 then make_variation() end
      trigger_step(position)
      redraw()
      grid_redraw()
    else
      clock.sleep(0.05)
    end
  end
end


local function arc_redraw()
  if not arc_device then return end
  local tau = math.pi * 2
  local values = {
    gate_probability / 100,
    pattern_index / #patterns,
    chaos / 100,
    loop_length / 16
  }

  arc_device:all(0)
  for ring = 1, 4 do
    arc_device:segment(ring, 0, tau * values[ring], 15)
    arc_device:led(ring, 1, 4)
  end
  arc_device:refresh()
end

local function setup_arc()
  arc_device = arc_source.connect()
  if not arc_device then return end

  arc_device.delta = function(ring, delta)
    local direction = delta > 0 and 1 or -1
    if ring == 1 then
      params:set("breakbeat_probability", clamp(gate_probability + delta, 0, 100))
    elseif ring == 2 then
      params:set("breakbeat_pattern", clamp(pattern_index + direction, 1, #patterns))
    elseif ring == 3 then
      params:set("breakbeat_chaos", clamp(chaos + delta, 0, 100))
    elseif ring == 4 then
      params:set("breakbeat_loop_length", clamp(loop_length + direction, 1, 16))
    end
  end
  arc_redraw()
end

function init()
  math.randomseed(os.time())

  for output = 1, 4 do
    crow.output[output].slew = 0
    crow.output[output].volts = 0
    crow.output[output].action = "pulse(0.01, 5, 1)"
  end

  crow.input[2].stream = function(volts)
    mutation_cv = clamp(volts * 20, -100, 100)
    update_mutation()
    redraw()
  end
  crow.input[2].mode("stream", 0.1)

  params:add_number("breakbeat_bpm", "BPM", 40, 240, 120)
  params:set_action("breakbeat_bpm", function(value)
    params:set("clock_tempo", value)
    redraw()
  end)

  params:add_option("breakbeat_pattern", "Pattern", (function()
    local names = {}
    for i, pattern in ipairs(patterns) do names[i] = pattern.name end
    return names
  end)(), 1)
  params:set_action("breakbeat_pattern", function(value)
    pattern_index = value
    position = 0
    make_variation()
    arc_redraw()
    redraw()
    grid_redraw()
  end)

  params:add_number("breakbeat_mutation", "Mutation", 0, 100, 0)
  params:set_action("breakbeat_mutation", function(value)
    mutation_base = value
    update_mutation()
    make_variation()
    redraw()
  end)

  params:add_number("breakbeat_probability", "Gate Probability", 0, 100, 100)
  params:set_action("breakbeat_probability", function(value)
    gate_probability = value
    arc_redraw()
    redraw()
  end)

  params:add_number("breakbeat_chaos", "Chaos", 0, 100, 0)
  params:set_action("breakbeat_chaos", function(value)
    chaos = value
    make_variation()
    arc_redraw()
    redraw()
  end)

  params:add_number("breakbeat_loop_length", "Loop Length", 1, 16, 16)
  params:set_action("breakbeat_loop_length", function(value)
    loop_length = value
    position = 0
    make_variation()
    arc_redraw()
    redraw()
    grid_redraw()
  end)

  params:set("clock_tempo", params:get("breakbeat_bpm"))
  make_variation()
  setup_arc()
  setup_grid()
  sequence_clock = clock.run(sequence_loop)
end

function enc(number, delta)
  if number == 1 then
    params:delta("breakbeat_bpm", delta)
  elseif number == 2 then
    params:delta("breakbeat_pattern", delta)
  elseif number == 3 then
    params:set("breakbeat_mutation", clamp(mutation_base + delta, 0, 100))
  end
end

function key(number, state)
  if state == 0 then return end

  if number == 2 then
    reset_pattern()
    grid_redraw()
  elseif number == 3 then
    playing = not playing
    if playing then
      position = 0
      make_variation()
    end
    redraw()
    grid_redraw()
  end
end

function redraw()
  screen.clear()
  screen.aa(0)

  screen.level(15)
  screen.font_size(8)
  screen.move(2, 7)
  screen.text(string.format("%02d %s", pattern_index, patterns[pattern_index].name))
  screen.move(126, 7)
  screen.text_right(playing and "PLAY" or "STOP")

  screen.font_face(1)
  screen.font_size(8)
  for lane = 1, 4 do
    local y = 17 + ((lane - 1) * 10)
    screen.level(10)
    screen.move(2, y)
    screen.text(lane_names[lane])

    for step = 1, 16 do
      local x = 13 + ((step - 1) * 7)
      if step == position and playing then
        screen.level(15)
        screen.rect(x - 1, y - 6, 6, 7)
        screen.stroke()
      end

      screen.level(step > loop_length and 1 or (current[lane][step] and 15 or 2))
      screen.move(x, y)
      screen.text(current[lane][step] and "x" or ".")
    end
  end

  screen.level(10)
  screen.font_size(8)
  screen.move(2, 63)
  screen.text("B" .. params:get("breakbeat_bpm") .. " M" .. math.floor(mutation + 0.5))
  screen.move(126, 63)
  screen.text_right("G" .. gate_probability .. " C" .. chaos .. " L" .. loop_length)
  screen.update()
end

function cleanup()
  if sequence_clock then clock.cancel(sequence_clock) end
  crow.input[2].mode("none")
  if arc_device and arc_device.cleanup then arc_device:cleanup() end
  if grid_device and grid_device.cleanup then grid_device:cleanup() end
  for output = 1, 4 do crow.output[output].volts = 0 end
end
