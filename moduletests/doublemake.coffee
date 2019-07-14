#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs
	traceEnabled:false

m.R 'oyakodon',['egg','chiken'],(g)->
	@T "making oyakodon[#{g}]"
	@T JSON.stringify(g.egg+g.chiken)
	return g.egg+g.chiken

m.R 'egg','god',(g)->
	new Promise (ok,ng)=>
		@T "making egg from #{g}"
		setTimeout =>
			ok g+1
		,1000

m.R 'god',(g)->
	@T "making god"
	9

m.R 'chiken',2

m.make 'oyakodon'
.then (x)=>
	m.O "1st:"+x
	m.make 'oyakodon'
.then (y)=>
	m.O "2nd:"+y

