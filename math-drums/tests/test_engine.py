from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('package.path = "'+str(root)+'/lib/?.lua;" .. package.path')
lua.execute('''
local engine=require('math_engine')
local function signature(events)
 local out={}; for _,e in ipairs(events) do out[#out+1]=string.format('%d:%.10f:%.10f',e.voice,e.time,e.value) end
 return table.concat(out,'|')
end
for seed=1,100 do for system=1,4 do
 local c={seed=seed,mutation=0,system=system,complexity=(seed%11)/10,chaos=(seed%7)/6,gravity=(seed%5)/4,coupling=.35}
 local events=engine.generate(c)
 assert(signature(events)==signature(engine.generate(c)))
 assert(#events<=160 and #events>=17)
 local last,first={},{}
 for _,e in ipairs(events) do
  assert(e.time>=0 and e.time<4 and e.value>=0 and e.value<=1)
  assert(not last[e.voice] or e.time-last[e.voice]>=1/32-1e-9)
  first[e.voice]=first[e.voice] or e.time; last[e.voice]=e.time
 end
 for v=1,4 do assert(4-last[v]+first[v]>=1/32-1e-9) end
 c.mutation=1
 assert(signature(engine.mutate(events,c,0))==signature(events))
 assert(signature(engine.mutate(events,c,1))==signature(engine.generate(c))))
end end
'''.replace('generate(c))))','generate(c)))'))
# Mock host: run the coroutine manually and inspect clock waits and output state.
lua.execute('''
package.preload.tabutil=function() return {save=function(t,p) snapshot=t end,load=function(p) return snapshot end} end
_path={data='/tmp/'}
controlspec={new=function(a,b,w,s,d) return {default=d,min=a,max=b} end}
params={values={},actions={},lookup={}}
function params:add_separator() end
function params:add_number(id,n,a,b,d) self.values[id]=d end
function params:add_option(id,n,o,d) self.values[id]=d end
function params:add_control(id,n,s) self.values[id]=s.default end
function params:add_trigger(id,n) self.values[id]=0 end
function params:set_action(id,f) self.actions[id]=f end
function params:get(id) return self.values[id] end
function params:set(id,v,silent) self.values[id]=v; if not silent and self.actions[id] then self.actions[id](v) end end
function params:delta(id,d) self:set(id,self:get(id)+d*.01) end
function params:bang() for id,f in pairs(self.actions) do if id~='save_pattern' and id~='load_pattern' then f(self.values[id]) end end end
clock={transport={},get_tempo=function() return 110 end}
function clock.run(f) co=coroutine.create(f); return 1 end
function clock.sync(d,o) coroutine.yield(d,o) end
function clock.cancel() co=nil end
crow={output={},reset=function() end}
for v=1,4 do crow.output[v]=setmetatable({},{__call=function(t) t.fired=(t.fired or 0)+1 end}) end
metro={init=function(f) return {start=function() end,stop=function() end} end}
screen=setmetatable({},{__index=function() return function() end end})
function include(path) return require('math_engine') end
''')
lua.execute((root/'math-drums.lua').read_text())
lua.execute('''
init(); redraw(); key(2,1)
local ok,d,o=coroutine.resume(co); assert(ok and d==4 and o==nil)
for i=1,20 do
 ok,d,o=coroutine.resume(co); assert(ok and d==4)
 assert(o==nil or (o>0 and o<4))
end
params.actions.save_pattern(); key(3,1); params.actions.load_pattern(); assert(snapshot.events)
key(2,1); assert(co==nil)
for v=1,4 do assert(crow.output[v].action=='{ to(0,0) }') end
cleanup()
''')
print('PASS: 400 engine configurations, repeatability, bounds, seam spacing, mutation, mocked host scheduling and cleanup')
