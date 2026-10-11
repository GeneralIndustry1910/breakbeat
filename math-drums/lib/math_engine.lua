-- Deterministic, bounded event trees. Times are quarter-note beats.
local M = {}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function rng(seed)
  local s=math.floor(seed)%2147483647
  if s<1 then s=1 end
  return function() s=(s*16807)%2147483647; return s/2147483647 end
end
function M.generate(c)
  local random=rng(c.seed+c.mutation*104729)
  local events,previous={},{}
  local prime={2,3,5,7,11,13,17}
  for v=1,4 do
    local x=random()*.8+.1
    local roots= v==1 and 4 or v==2 and 2 or v==3 and 8 or 3
    for n=1,roots do
      local t=(n-1)*4/roots+(v==2 and 1 or 0)
      t=t%4
      x=(3.5+.49*c.chaos)*x*(1-x)
      local coupled=(previous[n] or .5)
      local state=clamp(x*(1-c.coupling)+coupled*c.coupling,0,1)
      local root={time=t,voice=v,value=state,depth=0}
      events[#events+1]=root
      previous[n]=state
      local function branch(parent,depth,span)
        if depth>math.floor(c.complexity*3) or #events>=160 then return end
        if random()>c.complexity then return end
        local ratio
        if c.system==1 then ratio=1/prime[1+math.floor(state*6)]
        elseif c.system==2 then ratio=.25+.5*state
        elseif c.system==3 then ratio=.61803398875
        else ratio=({.25,.375,.5,.625})[1+((n+depth+v)%4)] end
        local raw=parent.time+span*ratio+(random()-.5)*c.chaos*.16
        local grid=math.floor(raw*4+.5)/4
        local time=raw*(1-c.gravity)+grid*c.gravity
        time=clamp(time,0,3.999)
        local child={time=time,voice=v,value=clamp(state+(random()-.5)*c.chaos,0,1),depth=depth,parent=parent}
        events[#events+1]=child
        branch(child,depth+1,span*.618)
      end
      branch(root,1,4/roots)
    end
  end
  table.sort(events,function(a,b) if a.time==b.time then return a.voice<b.voice end return a.time<b.time end)
  -- Enforce a per-output minimum spacing, including across the loop boundary.
  local result,last,first={}, {}, {}
  for _,e in ipairs(events) do
    if not last[e.voice] or e.time-last[e.voice]>=1/32 then
      result[#result+1]=e; last[e.voice]=e.time; first[e.voice]=first[e.voice] or e.time
    end
  end
  for i=#result,1,-1 do
    local e=result[i]
    if e.time==last[e.voice] and 4-e.time+first[e.voice]<1/32 then table.remove(result,i) end
  end
  return result
end
-- Replace only selected voices, preserving the others exactly.
function M.mutate(old,c,amount)
  local fresh=M.generate(c)
  local random=rng(c.seed+c.mutation*7919)
  local selected={}
  for v=1,4 do selected[v]=random()<amount end
  local out={}
  for _,e in ipairs(old) do if not selected[e.voice] then out[#out+1]=e end end
  for _,e in ipairs(fresh) do if selected[e.voice] then out[#out+1]=e end end
  table.sort(out,function(a,b) if a.time==b.time then return a.voice<b.voice end return a.time<b.time end)
  return out
end
return M
