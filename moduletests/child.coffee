#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

trace=false

m=new RecipeNodeJs
	traceEnabled:trace

m.R 'A','B',(g)->
	@T "making A"
	new Promise (rs,rj)=>
		setTimeout =>
			rs "#{g}A"
		,2000

m.R 'B',(g)->
	@T "making B"
	'B'

c=new RecipeNodeJs
	parent:m
	traceEnabled:trace

c.R 'C','A',(g)->
	"#{g}C"

gc=new RecipeNodeJs
	parent:c
	traceEnabled:trace

gc.R 'D','C',(g)->
	@O JSON.stringify "#{g}D"


gc.main 'D'
