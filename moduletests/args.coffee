#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs
	traceEnabled:false

m.R 'A',['value1','longoption','flag1','flag2'],(g)->
	r=g.value1+g.longoption
	r*=2 if g.flag1
	r*=3 if g.flag2
	console.log JSON.stringify r

m.R 'value1',0
m.R 'longoption',0
m.R 'flag1',false
m.R 'flag2',false
m.O m.setByArgv process.argv[2..],
	b:'value1:'
	f:'flag1'

m.main 'A'
