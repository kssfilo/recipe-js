#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

trace=false

m=new RecipeNodeJs
	traceEnabled:false

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
	traceEnabled:false

c.R 'C','A',(g)->
	"#{g}C"

gc=new RecipeNodeJs
	parent:c
	traceEnabled:false

gc.R 'D','C',(g)->
	"#{g}D"


gc.main 'D'
