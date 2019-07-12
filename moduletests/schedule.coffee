#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs
	traceEnabled:false
	traceScheduler:false

m.set 'counter',0

m.R 'timer1',(g)->
	@T "timer1"
	v=@get 'counter'
	@set 'counter',++v
	@C  "#{v}"
	true

toggle=true

m.R 'timer2',(g)->
	@T "timer2"
	toggle=!toggle
	@.enableSchedule 'theTimer',toggle
	true

m.R 'timer3',(g)->
	@T "timer3"
	['theTimer','timer2'].map (x)=>@clearSchedule x

m.R 'oneshot',(g)->
	v=@get 'counter'
	@set 'counter',(v+1000)
	@clearSchedule 'timeofday'

m.R 'timeofday',(g)->
	v=@get 'counter'
	@set 'counter',(v+100)

#m.main 'oyakodon'

m.schedule 1,'timer1','theTimer'
m.schedule -3,'timer2'
m.schedule '+10','timer3'

now=new Date().getTime()
offset=new Date().getTimezoneOffset()*60000

m.schedule new Date(now+65000).toString(),'oneshot'

target=now+=60000
d=new Date(target)

m.schedule "#{d.getHours()}:#{d.getMinutes()}",'timeofday'

m.run('counter')
.then (r)->
	console.log "finished:#{r}"
.catch (e)->
	console.log "failed:#{e}"

