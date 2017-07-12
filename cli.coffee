#!/usr/bin/env coffee
###jshint evil:true###

{RecipeNodeJs}=require './recipejs'
CoffeeScript=require 'coffee-script'
Fs=require 'fs'

$=new RecipeNodeJs()

recipefile='Recipefile'

if process.argv[2] in ['-h','-?']
	$.O """
	recipe [-F <Recipefile>] [target] [-<option> --<option> ..]

	A gulp/GNU make like task launcher.Supports Dependencies/Inference Rules/Promise/Child Process/Cache/Deriving/CLI.

	Options:

	-F <Recipefile> specify Recipefile,default is "./Recipefile"
	<target>:specify target object, default target is 'default'
	<option>:options for Recipefile

	Recipefile example:
	-----
	# coffee script syntax

	# 'default' needs 'prereq0-3', result -> 'Hello World RecipeJs' 
	$.R 'default',['prereq0','prereq1','prereq2'],(g)->
		console.log "\#{g.prereq0} \#{g.prereq1} \#{g.prereq2}"

	# 'prereq0' needs no prerequisite, -> 'Hello'
	$.R 'prereq0',->
		new Promise (rs,rj)->
			setTimeout ->
				rs 'Hello'
			,1000

	# 'prereq1' needs 'prereq1A', g is 'world' , 'prereq1' -> 'World'
	$.R 'prereq1','prereq1A',(g)->
		g.replace /^w/,'W'

	# 'prereq1A' is 'world' (same as $.R 'prereq1A',->'world')
	$.set 'prereq1A','world'

	# 'prereq2' needs 'prereq2A', g is 'recipejs', 'prereq2' will be 'RecipeJs'
	# @S(this.S=$.S) execlutes child process with stdin(2nd arg)
	# @P(this.P=$.P) is short hand of (g)->@S cmd,g
	$.R 'prereq2','prereq2A',(g)->
		@S 'sed s/^r/R/',g
		.then @P 'sed s/js$/Js/'

	$.R 'prereq2A',->'recipejs'
	-----
	Example:(with option)
	-----
	$.R 'default',['flagA','argB','flagC','argD'],(g)->
		console.log "\#{g.flagA} \#{g.argB} \#{g.flagC} \#{g.argD}"

	#defaults
	$.set 'flagA',false
	$.set 'argB','-' 
	$.set 'flagC',false
	$.set 'argD','-'

	#special target 'OPTIONS' 
	$.set 'OPTIONS',
		a:'flagA'
		b:'argB:' #':' indicates having argument

	#command line: recipe -a -b Hello --flagC --argD=World
	#->true Hello true World
	-----
	Example:(file/inference rules)
	-----
	# $.F tells that specified target(extension/filename) is files.
	$.F ['.md','.html']

	$.R '.html','.md',$.P 'md2html'

	#>recipe test.html
	# ->file test.md(# Hello) -> file test.html (<h1>Hello</h1>)
	# file system's timestamp is used for update decision
	"""
	process.exit 0

if process.argv[2] is '-F'
	recipefile=process.argv[3]
	process.argv.splice 0,4
else
	process.argv.splice 0,2

try
	r=Fs.readFileSync recipefile
	eval CoffeeScript.compile r.toString()

	options=$.get 'OPTIONS'
	remains=$.setByArgv process.argv,options

	target=remains[0] ? 'default'
	$.main target
catch e
	$.E e
