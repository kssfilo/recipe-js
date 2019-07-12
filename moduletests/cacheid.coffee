#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

cacheId="recipe-js-building-test"
path=require('path')
fn=path.join(process.env.HOME,".recipe-js","#{cacheId}.json")

if require('fs').existsSync fn
	require('fs').unlinkSync fn

m=new RecipeNodeJs
	#debugEnabled:true
	cacheId:cacheId

m.R 'cache',->
	@cache 'cache','hello',2

m.R 'default','cache',(g)->console.log g

m.make 'default'
.then ->
	r=require('fs').readFileSync(fn,'utf-8')
	r=JSON.parse r
	console.log (k for k,v of r.cache)
	
	if require('fs').existsSync fn
		require('fs').unlinkSync fn
