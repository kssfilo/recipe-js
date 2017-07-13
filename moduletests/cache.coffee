#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

m=new RecipeNodeJs
	debugEnabled:false

m.R 'cache',->
	@cache 'cache','hello',2

m.R 'default','cache',(g)->console.log g

m.make 'default'
.then ->
	m._cache['cache'].v='fromcache'

	setTimeout ->
		m.remake 'default'
	,1000

	setTimeout ->
		m.remake 'default'
	,3000


