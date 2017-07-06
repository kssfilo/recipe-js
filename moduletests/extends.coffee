#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

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

ec=new RecipeNodeJs
	extends:c
	traceEnabled:trace

ec.R 'D','C',(g)->
	"#{g}D"

eec=new RecipeNodeJs
	extends:ec
	traceEnabled:trace

eec.R 'E','D',(g)->
	"#{g}D"

eec.make 'E'
.then (x)->
	eec.O "E=#{x},ec.C=#{eec._objs['C']},ec.B=#{eec._objs['B']}"
	process.exit 0

