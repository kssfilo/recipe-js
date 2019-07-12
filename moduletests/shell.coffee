#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs
	traceEnabled:false

m.R 'seed',->
	@S 'echo "Hello Town"'

m.R 'proc1','seed',(x)->
	Promise.resolve x
	.then @P 'sed s/Town/City/|sed s/City/Prefecture/'
	.then @P 'sed s/Prefecture/Country/'

m.R 'proc2','proc1',m.P 'sed "s/\\(.*\\)Country/\|\\1World\|/"'

m.R 'proc3','proc2',(g)->console.log JSON.stringify g

m.main 'proc3'
