#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

m=new RecipeNodeJs
	traceEnabled:false

m.R 'oyakodon',['egg','chiken'],(g)->
	@T "making oyakodon[#{g}]"
	g.egg+g.chiken

m.R 'egg',['god','chiken'],(g)->
	new Promise (ok,ng)=>
		@T "making egg from #{g}"
		setTimeout =>
			ok g+1
		,1000

m.R 'god',(g)->
	@T "making god"
	9

m.R 'chiken','egg',(x)->x

m.main 'oyakodon'
