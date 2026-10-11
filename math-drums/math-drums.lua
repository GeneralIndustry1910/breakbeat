-- math-drums: coupled mathematical percussion for norns + crow
-- K2 play/stop; K3 mutate; hold K1 for alternate controls
-- E1 complexity; E2 chaos; E3 gravity
local tab=require('tabutil')
local math_engine=include('math-drums/lib/math_engine')
local running=false
local task,refresh
local pattern,pending={},nil
local held=false
local page=1
local mutation=0
local phase=0
local frozen=false
local dirty=true
local flashes={0,0,0,0}
local names={'K','S','H','P'}
local systems={'prime tree','logistic','golden tree','modular'}
local function config()
  return {seed=params:get('seed'),mutation=mutation,complexity=params:get('complexity'),
    chaos=params:get('chaos'),gravity=params:get('gravity'),coupling=params:get('coupling'),system=params:get('system')}
end
local function regenerate()
  mutation=0
  pending=math_engine.generate(config())
  if not running then pattern=pending; pending=nil end
  dirty=true
end
local function silence()
  for i=1,4 do
    crow.output[i].action='{ to(0,0) }'
    crow.output[i]()
  end
end
local function fire(e)
  local v=e.voice
  if params:get('mute_'..v)==2 then return end
  local mode=params:get('mode_'..v)
  local level=params:get('level_'..v)
  if mode==3 then
    crow.output[v].slew=params:get('slew_'..v)/1000
    crow.output[v].volts=e.value*level
  else
    -- Explicit low segment guarantees a fresh rising edge on retrigger.
    local duration=mode==1 and .01 or params:get('width_'..v)/1000
    crow.output[v].action=string.format('{ to(0,0), to(%.4f,0), to(%.4f,%.4f), to(0,0) }',level,level,duration)
    crow.output[v]()
  end
  flashes[v]=3; dirty=true
end
local function stop()
  running=false
  if task then clock.cancel(task); task=nil end
  silence(); phase=0; dirty=true
end
local function start()
  if running then return end
  running=true
  task=clock.run(function()
    clock.sync(4)
    while running do
      if pending then pattern=pending; pending=nil end
      local elapsed=0
      for _,e in ipairs(pattern) do
        local delta=e.time-elapsed
        if delta>0 then clock.sync(4,e.time) end
        if not running then return end
        phase=e.time; fire(e); elapsed=e.time
      end
      clock.sync(4)
      phase=0; dirty=true
    end
  end)
end
local function mutate(amount)
  if frozen then return end
  mutation=mutation+1
  pending=math_engine.mutate(pending or pattern,config(),amount)
  if not running then pattern=pending; pending=nil end
  dirty=true
end
function init()
  params:add_separator('math_drums','MATH DRUMS')
  params:add_number('seed','seed',1,999999,1910)
  params:add_option('system','system',systems,2)
  for _,p in ipairs({{'complexity',.63},{'chaos',.21},{'gravity',.78},{'coupling',.35}}) do
    params:add_control(p[1],p[1],controlspec.new(0,1,'lin',.01,p[2]))
    params:set_action(p[1],regenerate)
  end
  params:set_action('seed',regenerate); params:set_action('system',regenerate)
  for v=1,4 do
    local voice=v
    params:add_separator('voice_'..v,'CROW '..v)
    params:add_option('mode_'..v,'output mode',{'trigger','gate','CV'},v==4 and 3 or 1)
    params:set_action('mode_'..v,function() crow.output[voice].action='{ to(0,0) }'; crow.output[voice]() end)
    params:add_option('mute_'..v,'mute',{'off','on'},1)
    params:set_action('mute_'..v,function(value) if value==2 then crow.output[voice].action='{ to(0,0) }'; crow.output[voice]() end end)
    params:add_control('level_'..v,'voltage',controlspec.new(0,5,'lin',.1,5,'V'))
    params:add_number('width_'..v,'gate length ms',1,500,40)
    params:add_number('slew_'..v,'CV slew ms',0,1000,30)
  end
  params:add_separator('snapshot','PATTERN SNAPSHOT')
  params:add_trigger('save_pattern','save current pattern')
  params:set_action('save_pattern',function()
    tab.save({events=pending or pattern,config=config()},_path.data..'math-drums/pattern.data')
  end)
  params:add_trigger('load_pattern','load saved pattern')
  params:set_action('load_pattern',function()
    local saved=tab.load(_path.data..'math-drums/pattern.data')
    if not saved or not saved.events or not saved.config then return end
    for _,id in ipairs({'seed','system','complexity','chaos','gravity','coupling'}) do
      params:set(id,saved.config[id],true)
    end
    mutation=saved.config.mutation or 0
    pending=saved.events
    if not running then pattern=pending; pending=nil end
    dirty=true
  end)
  -- Disable the global crow clock output so it cannot fight this script.
  if params.lookup['clock_crow_out'] then params:set('clock_crow_out',1) end
  crow.reset()
  params:bang(); regenerate(); silence()
  clock.transport.start=start
  clock.transport.stop=stop
  refresh=metro.init(function()
    for v=1,4 do if flashes[v]>0 then flashes[v]=flashes[v]-1; dirty=true end end
    if dirty then redraw(); dirty=false end
  end,1/20,-1)
  refresh:start()
end
function key(n,z)
  if n==1 then held=z==1; dirty=true; return end
  if z==0 then return end
  if n==2 then
    if held then frozen=not frozen else if running then stop() else start() end end
  elseif n==3 then
    if held then params:set('seed',params:get('seed')%999999+1) else mutate(.35) end
  end
  dirty=true
end
function enc(n,d)
  if held then
    if n==1 then page=page==1 and 2 or 1
    elseif n==2 then params:delta('system',d)
    else params:delta('coupling',d) end
  else params:delta(({'complexity','chaos','gravity'})[n],d) end
  dirty=true
end
function redraw()
  screen.clear(); screen.level(15); screen.move(1,8)
  screen.text(running and 'MATH >' or 'MATH ||')
  screen.move(128,8); screen.text_right(string.format('%d BPM',clock.get_tempo()))
  if page==1 then
    for v=1,4 do
      local y=15+v*8
      screen.level(flashes[v]>0 and 15 or 5); screen.move(1,y+2); screen.text(names[v])
      screen.level(2); screen.move(12,y); screen.line(126,y); screen.stroke()
    end
    for _,e in ipairs(pattern) do
      local x=12+e.time/4*114; local y=15+e.voice*8
      if e.parent then
        local px=12+e.parent.time/4*114
        screen.level(3); screen.move(px,y)
        for j=1,6 do local f=j/6; screen.line(px+(x-px)*f,y-math.sin(f*math.pi)*4) end
        screen.stroke()
      end
      screen.level(e.depth==0 and 12 or 6); screen.circle(x,y,1); screen.fill()
    end
    screen.level(15); screen.move(12+phase/4*114,18); screen.line(12+phase/4*114,50); screen.stroke()
  else
    screen.level(12); screen.move(1,22); screen.text(systems[params:get('system')])
    screen.move(1,33); screen.text('seed '..params:get('seed')..' / mut '..mutation)
    screen.move(1,44); screen.text(string.format('couple %.2f %s',params:get('coupling'),frozen and 'FROZEN' or ''))
  end
  screen.level(10); screen.move(1,62)
  if held then screen.text('E1 page E2 sys E3 couple')
  else screen.text(string.format('C %.2f X %.2f G %.2f',params:get('complexity'),params:get('chaos'),params:get('gravity'))) end
  screen.update()
end
function cleanup()
  stop()
  if refresh then refresh:stop() end
  clock.transport.start=nil; clock.transport.stop=nil
end
