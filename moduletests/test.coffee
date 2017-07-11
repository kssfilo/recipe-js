#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

m=new RecipeNodeJs()

m.R 'log','result',(x)->@cache 'log',x
m.R 'result','target',(t)->m.S "coffee #{t}.coffee"

m.R 'test',['log','result','target'],(g)->
	if g.log isnt g.result
		return "#{g.target} Failed:#{g.log} vs #{g.result}"
	else
		return "#{g.target} OK"

ts=['extends','child','basic','shell','loop','args','schedule','abstruct'].map (x)->
	r=new RecipeNodeJs
		extends:m
		cacheFile:"#{x}.json"
		traceEnabled:false
		set:
			target:x

	if x is 'args'
		r.R 'result','target',(t)->
			@S "coffee #{t}.coffee -f --flag2 -b 1 --longoption=2 other args "
	r

m.O 'This test needs 1min-2min. please wait'
m.main ts,'test'

