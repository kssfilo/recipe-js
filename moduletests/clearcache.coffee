#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipe-js'

m=new RecipeNodeJs
	debugEnabled:false

m.R 'cache',->
	@cache 'cache','hello',10

m.R 'cache2',->
	@cache 'cache2','world',10

m.R 'default',['cache','cache2'],(g)->console.log g

m.make 'default'
.then ->
	m._cache['cache'].v='fromcache'
	m._cache['cache2'].v='fromcache'

	setTimeout ->
		m.remake 'default'
		.then ()=>
			m.clearCache('cache2')
			true
	,1000

	setTimeout ->
		m.remake 'default'
		.then ()=>
			m.clearCache()
			true
	,3000

	setTimeout ->
		m.remake 'default'
	,5000

