#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs()

m.R 'log','result',(x)->@cache 'log',x
m.R 'result','target',(t)->m.S "../node_modules/.bin/coffee #{t}.coffee"

m.R 'test',['log','result','target'],(g)->
	if g.log isnt g.result
		return "#{g.target} Failed:#{g.log} vs #{g.result}"
	else
		return "#{g.target} OK"

tests=['extends','child','basic','shell','loop','args','cache','cachefile','clearcache','cacheid','abstruct']
tests.push('schedule')

ts=tests.map (x)->
	r=new RecipeNodeJs
		extends:m
		cacheFile:"#{x}.json"
		traceEnabled:false
		set:
			target:x

	if x is 'args'
		r.R 'result','target',(t)->
			@S "../node_modules/.bin/coffee #{t}.coffee -f --flag2 -b 1 --longoption=2 other args "
	r

m.O 'This test needs 0min-2min. please wait'
m.main ts,'test'

