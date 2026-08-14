-- breakbeat
-- four-lane breakbeat trigger sequencer for norns + crow
-- v1.0.0

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
  { name = "Ruff Break",    kick = "x.....x.x..x..x.", snare = "...xx......xx...", hat = "xxx.x.x.xxx.xxxx", perc = "..x....x..x....x" }
}

local lane_keys = { "kick", "snare", "hat", "perc" }
local lane_names = { "K", "S", "H", "P" }
local pattern_index = 1
local mutation = 0
local position = 0
local playing = true
local sequence_clock = nil
local current = {}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

local function copy_pattern()
  current = {}
  local source = patterns[pattern_index]

  for lane = 1, 4 do
    local row = {}
    local text = source[lane_keys[lane]]
    for step = 1, 16 do
      row[step] = text:sub(step, step) == "x"
    end
    current[lane] = row
  end
end

local function make_variation()
  copy_pattern()
  if mutation == 0 then return end

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

local function trigger_step(step)
  for lane = 1, 4 do
    if current[lane][step] then
      crow.output[lane]()
    end
  end
end

local function sequence_loop()
  while true do
    if playing then
      clock.sync(1 / 4)
      position = (position % 16) + 1
      if position == 1 then make_variation() end
      trigger_step(position)
      redraw()
    else
      clock.sleep(0.05)
    end
  end
end

function init()
  math.randomseed(os.time())

  for output = 1, 4 do
    crow.output[output].slew = 0
    crow.output[output].volts = 0
    crow.output[output].action = "pulse(0.01, 5, 1)"
  end

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
    redraw()
  end)

  params:add_number("breakbeat_mutation", "Mutation", 0, 100, 0)
  params:set_action("breakbeat_mutation", function(value)
    mutation = value
    make_variation()
    redraw()
  end)

  params:set("clock_tempo", params:get("breakbeat_bpm"))
  make_variation()
  sequence_clock = clock.run(sequence_loop)
end

function enc(number, delta)
  if number == 1 then
    params:delta("breakbeat_bpm", delta)
  elseif number == 2 then
    params:delta("breakbeat_pattern", delta)
  elseif number == 3 then
    params:set("breakbeat_mutation", clamp(mutation + delta, 0, 100))
  end
end

function key(number, state)
  if state == 0 then return end

  if number == 2 then
    position = 0
    make_variation()
    redraw()
  elseif number == 3 then
    playing = not playing
    if playing then
      position = 0
      make_variation()
    end
    redraw()
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

      screen.level(current[lane][step] and 15 or 2)
      screen.move(x, y)
      screen.text(current[lane][step] and "x" or ".")
    end
  end

  screen.level(10)
  screen.font_size(8)
  screen.move(2, 63)
  screen.text("BPM " .. params:get("breakbeat_bpm"))
  screen.move(126, 63)
  screen.text_right("MUT " .. mutation .. "%  K3 " .. (playing and "STOP" or "PLAY"))
  screen.update()
end

function cleanup()
  if sequence_clock then clock.cancel(sequence_clock) end
  for output = 1, 4 do crow.output[output].volts = 0 end
end
