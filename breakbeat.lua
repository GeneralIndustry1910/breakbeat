-- breakbeat
-- four-lane breakbeat trigger sequencer for norns + crow
-- v1.4.0

local arc_source = arc
local grid_source = grid
local toga_enabled = util.file_exists(_path.code .. "toga/lib/togagrid.lua")
if toga_enabled then
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
  { name = "Glitch Break",  kick = "x.x....x..x.x...", snare = "...xx.....x.x..x", hat = "xx.xxxx.xx.xxxxx", perc = ".x....xx...x..x." },
  { name = "Off Kilter",    kick = "x....x....x..x..", snare = "......x......x..", hat = "x.x..x.x.x..x.x.", perc = "...x....x..x...." },
  { name = "Lopsided",      kick = "x......x..x....x", snare = "...x......x.....", hat = "x..x.x..x.x..x.x", perc = ".....x..x....x.." },
  { name = "Late Snare",    kick = "x....x...x......", snare = ".....x.......x..", hat = "x.x.x..xx.x.x..x", perc = "...x......x..x.." },
  { name = "Skipping",      kick = "x..x.....x....x.", snare = "......x....x....", hat = "xx..x.xxx..x.x..", perc = "....x....x....x." },
  { name = "Displaced",     kick = "..x....x....x...", snare = "......x.......x.", hat = ".x.x.x.x.x.x.x.x", perc = "x....x....x....x" },
  { name = "Tripwire",      kick = "x......x.x.....x", snare = "...x.......x....", hat = "x.xx..x.x..xx.x.", perc = ".....x....x..x.." },
  { name = "Stumble",       kick = "x....x.x.....x..", snare = ".......x....x...", hat = "xx.x..xxx.x..x.x", perc = "...x......x....x" },
  { name = "Sideways",      kick = "..x..x.....x..x.", snare = ".....x......x...", hat = "x..xx.x..xx.x..x", perc = "x......x.....x.." },
  { name = "Four on Floor", kick = "x...x...x...x...", snare = "....x.......x...", hat = "x.x.x.x.x.x.x.x.", perc = "................" },
  { name = "Driving Techno",kick = "x...x...x...x...", snare = "....x.......x...", hat = ".x.x.x.x.x.x.x.x", perc = "..x...x...x...x." },
  { name = "Warehouse",     kick = "x...x...x...x...", snare = "....x.......x...", hat = "xxxxxxxxxxxxxxxx", perc = "...x...x...x...x" },
  { name = "Minimal Techno",kick = "x...x...x...x...", snare = "........x.......", hat = "..x...x...x...x.", perc = "......x......x.." },
  { name = "Rumble Techno", kick = "x...x...x...x...", snare = "....x.......x...", hat = "x.x.xx.x.x.x.xx.", perc = "...x...x...x...x" },
  { name = "Peak Time",     kick = "x...x...x...x...", snare = "....x.......x...", hat = "xxxxxxxxxxxxxxxx", perc = "..x.....x...x..." }
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
local old_osc_event = nil
local ratchet_pulses = { 0, 1, 2, 4 }
local lane_muted = { false, false, false, false }
local roll_active = { false, false, false, false }
local roll_clocks = {}
local step_press = {}

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
      rows[lane][step] = text:sub(step, step) == "x" and 1 or 0
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
          current[lane][step] = current[lane][step] > 0 and 0 or 1
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

local function cycle_step(lane, step)
  local pattern = editable_pattern()
  pattern[lane][step] = (pattern[lane][step] + 1) % 4
  make_variation()
  redraw()
end

local function clear_step(lane, step)
  local pattern = editable_pattern()
  pattern[lane][step] = 0
  make_variation()
  redraw()
end

local function grid_redraw()
  if not grid_device then return end
  grid_device:all(0)

  for lane = 1, 4 do
    for step = 1, 16 do
      local mode = current[lane][step]
      local level = ({ 1, 8, 12, 15 })[mode + 1]
      if step > loop_length then level = mode > 0 and 3 or 0 end
      if playing and step == position then level = math.max(level, 14) end
      if lane_muted[lane] then level = math.min(level, 2) end
      grid_device:led(step, lane, level)
    end
  end

  for index = 1, #patterns do
    local x = ((index - 1) % 16) + 1
    local y = math.floor((index - 1) / 16) + 5
    grid_device:led(x, y, index == pattern_index and 15 or 3)
  end

  -- Bottom-right button restores the selected pattern's authored version.
  grid_device:led(16, 8, 10)
  grid_device:refresh()
end

local function roll_loop(lane)
  while roll_active[lane] do
    if not lane_muted[lane] then crow.output[lane]() end
    clock.sync(1 / 4)
  end
end

local function start_roll(lane)
  if roll_active[lane] then return end
  roll_active[lane] = true
  roll_clocks[lane] = clock.run(roll_loop, lane)
end

local function stop_roll(lane)
  roll_active[lane] = false
  if roll_clocks[lane] then
    clock.cancel(roll_clocks[lane])
    roll_clocks[lane] = nil
  end
end

local function toggle_mute(lane)
  lane_muted[lane] = not lane_muted[lane]
  grid_redraw()
  redraw()
end

local function control_redraw()
  if not grid_device or not grid_device.dest then return end
  local selected = {
    math.floor((gate_probability / 100) * 15 + 0.5) + 1,
    math.floor((mutation_base / 100) * 15 + 0.5) + 1,
    math.floor((chaos / 100) * 15 + 0.5) + 1,
    loop_length
  }

  for _, destination in pairs(grid_device.dest) do
    for row = 1, 4 do
      for column = 1, 16 do
        local index = column + ((row - 1) * 16)
        osc.send(destination, "/breakbeatcontrol/" .. index,
          { column == selected[row] and 1 or 0 })
      end
    end
    for lane = 1, 4 do
      osc.send(destination, "/breakbeatmute/" .. lane,
        { lane_muted[lane] and 1 or 0 })
      osc.send(destination, "/breakbeatroll/" .. lane,
        { roll_active[lane] and 1 or 0 })
    end
  end
end

local function handle_touchosc_control(path, args)
  local prefix = "/breakbeatcontrol/"
  local index = tonumber(path:sub(#prefix + 1))
  if not index or index < 1 or index > 64 then return end
  if not args[1] or args[1] <= 0 then
    control_redraw()
    return
  end

  local column = ((index - 1) % 16) + 1
  local row = math.floor((index - 1) / 16) + 1
  if row == 1 then
    params:set("breakbeat_probability", math.floor(((column - 1) / 15) * 100 + 0.5))
  elseif row == 2 then
    params:set("breakbeat_mutation", math.floor(((column - 1) / 15) * 100 + 0.5))
  elseif row == 3 then
    params:set("breakbeat_chaos", math.floor(((column - 1) / 15) * 100 + 0.5))
  elseif row == 4 then
    params:set("breakbeat_loop_length", column)
  end
  control_redraw()
end

local function lane_from_path(path, prefix)
  local lane = tonumber(path:sub(#prefix + 1))
  if lane and lane >= 1 and lane <= 4 then return lane end
  return nil
end

local function setup_touchosc()
  old_osc_event = osc.event
  osc.event = function(path, args, from)
    local control_prefix = "/breakbeatcontrol/"
    local mute_prefix = "/breakbeatmute/"
    local roll_prefix = "/breakbeatroll/"
    if path:sub(1, #control_prefix) == control_prefix then
      handle_touchosc_control(path, args)
      return
    elseif path:sub(1, #mute_prefix) == mute_prefix then
      local lane = lane_from_path(path, mute_prefix)
      if lane and args[1] and args[1] > 0 then toggle_mute(lane) end
      control_redraw()
      return
    elseif path:sub(1, #roll_prefix) == roll_prefix then
      local lane = lane_from_path(path, roll_prefix)
      if lane then
        if args[1] and args[1] > 0 then start_roll(lane) else stop_roll(lane) end
      end
      control_redraw()
      return
    end

    if old_osc_event then old_osc_event(path, args, from) end
    if path:sub(1, 16) == "/toga_connection" then control_redraw() end
  end
end

local function setup_grid()
  grid_device = grid_source.connect()
  if not grid_device then return end

  grid_device.key = function(x, y, z)
    if y >= 1 and y <= 4 and x >= 1 and x <= 16 then
      step_press[y] = step_press[y] or {}
      if z > 0 then
        step_press[y][x] = clock.get_beats()
      else
        local started = step_press[y][x]
        step_press[y][x] = nil
        if started then
          local held_seconds = (clock.get_beats() - started) * clock.get_beat_sec()
          if held_seconds >= 0.45 then clear_step(y, x) else cycle_step(y, x) end
          grid_redraw()
        end
      end
      return
    end

    if z == 0 then return end
    if y >= 5 and y <= 7 then
      local selected = x + ((y - 5) * 16)
      if selected <= #patterns then params:set("breakbeat_pattern", selected) end
    elseif x == 16 and y == 8 then
      reset_pattern()
      grid_redraw()
    end
  end
  grid_redraw()
end

local function fire_ratchet(lane, pulses)
  for pulse = 1, pulses do
    crow.output[lane]()
    if pulse < pulses then clock.sync(1 / (4 * pulses)) end
  end
end

local function trigger_step(step)
  for lane = 1, 4 do
    local pulses = ratchet_pulses[current[lane][step] + 1]
    if not lane_muted[lane] and pulses > 0 and math.random(100) <= gate_probability then
      if pulses == 1 then
        crow.output[lane]()
      else
        clock.run(fire_ratchet, lane, pulses)
      end
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
    control_redraw()
    redraw()
    grid_redraw()
  end)

  params:add_number("breakbeat_probability", "Gate Probability", 0, 100, 100)
  params:set_action("breakbeat_probability", function(value)
    gate_probability = value
    arc_redraw()
    control_redraw()
    redraw()
  end)

  params:add_number("breakbeat_chaos", "Chaos", 0, 100, 0)
  params:set_action("breakbeat_chaos", function(value)
    chaos = value
    make_variation()
    arc_redraw()
    control_redraw()
    redraw()
    grid_redraw()
  end)

  params:add_number("breakbeat_loop_length", "Loop Length", 1, 16, 16)
  params:set_action("breakbeat_loop_length", function(value)
    loop_length = value
    position = 0
    make_variation()
    arc_redraw()
    control_redraw()
    redraw()
    grid_redraw()
  end)

  params:set("clock_tempo", params:get("breakbeat_bpm"))
  make_variation()
  setup_arc()
  setup_grid()
  setup_touchosc()
  control_redraw()
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

      local mode = current[lane][step]
      local symbol = ({ ".", "x", "2", "4" })[mode + 1]
      screen.level(step > loop_length and 1 or (mode > 0 and 15 or 2))
      screen.move(x, y)
      screen.text(symbol)
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
  for lane = 1, 4 do stop_roll(lane) end
  crow.input[2].mode("none")
  if old_osc_event then osc.event = old_osc_event end
  if arc_device and arc_device.cleanup then arc_device:cleanup() end
  if grid_device and grid_device.cleanup then grid_device:cleanup() end
  for output = 1, 4 do crow.output[output].volts = 0 end
end
