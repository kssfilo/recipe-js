#!/usr/bin/env coffee

{RecipeNodeJs}=require '../dist/recipejs'

$=new RecipeNodeJs
	traceEnabled:false

$.R '.html','.md',$.P 'sed -E "s/^# (.*)/<h1>\\1<\\/h1>/"'

$.set 'test.md','# Hello World'
$.set 'test2.md','# Hello RecipeJs'

$.R 'default',['test.html','test2.html'],(g)->"#{g['test.html']}#{g['test2.html']}"

$.make 'default'
.then (g)->console.log g
