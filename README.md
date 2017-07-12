recipe-js
==========

A gulp/GNU make like task launcher.Supports Dependencies/Inference Rules/Promise/Child Process/Cache/Deriving/CLI.

## Examples

### Core module (RecipeJs class)

```
RecipeJs=require('recipe-js').RecipeJs;

$=new RecipeJs();

$.R('default',['prereq0','prereq1'],(g)=>{
	return(`${g.prereq0} ${g.prereq1}`);
});

$.set('prereq0','Hello');

$.R('prereq1',()=>{
	return new Promise((rs,rv)=>{
		setTimeout(()=>{
			rs('World');
		},1000);
	});
});

$.make('default')
.then((g)=>{
	console.log(g);
});

//-> Hello World
```

### Nodejs module (RecipeNodeJs class extended from RecipeJs)

```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs();

$.R('default',['prereq0','prereq1'],(g)=>{
	console.log(`${g.prereq0} ${g.prereq1}`);
});

$.R('prereq0',$.P("echo -n Hello"));

$.R('prereq1',()=>{
	return $.S('whoami')
	.then($.P('sed s/^/Mr./'));
});

$.main('default');

//-> Hello Mr.username
//$.P(cmd) is short hand for (stdin)=>$.S(cmd,stdin)
```

### Inference Rules(.)

```
RecipeJs=require('recipe-js').RecipeJs;

$=new RecipeJs(); 

$.R('%.html','%.md',(g)=>{
	return g.replace(/^## (.*)/,'<h2>$1</h2>')
});

$.set('prereq0.md','## Hello');
$.set('prereq1.md','## RecipeJs');

$.R('default',['prereq0.html','prereq1.html'],(g)=>{
	return(g['prereq0.html']+g['prereq1.html']);
});

$.make('default')
.then((g)=>{
	console.log(g);
});
//-> <h2>Hello</h2><h2>RecipeJs</h2>
//% is wildcard, regex is ok like '(.*)\.html','$1.md'
```

### File IO

```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs(); 

// $.F tells that specified targets(extension/filename) are files.
$.F('%.md');
$.F('%.html');

$.R('%.html','%.md',$.P('md2html'));

$.R('default',['prereq0.html']);

$.main('default'); //must be main() not make() for saving results
//-> file prereq0.md(# Hello) -> file prereq0.html (<h1>Hello</h1>) 
//file system's timestamp is used for update decision
```

### Cache / Trace

```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs({
	cacheFile:'cache.json',
	traceEnabled:true
});

$.R('default','prereq0',(g)=>{
	console.log(`Hello ${g}`);
});

$.R('prereq0',()=>{
	return $.S('whoami')
	.then((r)=>{
		return $.cache('prereq0',r,180); //cache time:180sec,null is forever
	});
});

$.main('default'); 

//-> result will be saved in 'cache.json' with data '{"prereq0":{"v":"user\n","expire":1499307137335}}'
```

### Deriving (extends)

```
RecipeJs=require('recipe-js').RecipeJs;

parent=new RecipeJs(); 

parent.R('default','prereq0',(g)=>{
	console.log(`Hello ${g}`);
});

child=new RecipeJs({
	extends:parent
}); 

child.R('prereq0',()=>{
	return('World');
});

child.make('default'); 
//-> Hello World ('prereq0' would be stored in 'child' object)
```
### Deriving (parent)

```
RecipeJs=require('recipe-js').RecipeJs;

parent=new RecipeJs(); 

parent.R('prereq0',()=>{
	return('World');
});

child=new RecipeJs({
	parent:parent
}); 

child.R('default','prereq0',(g)=>{
	console.log(`Hello ${g}`);
});


child.make('default'); 
//-> Hello World ('prereq0' would be stored in 'parent' object for sharing results by children)
```

### Command line parser

```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs();

$.R('default',['prereq0','prereq1','prereq2'],(g)=>{
	console.log(`${g.prereq0} ${g.prereq1} ${g.prereq2}`);
});

$.R('prereq0','-');  //defaults
$.R('prereq1',false);
$.R('prereq2','-');

remains=$.setByArgv(process.argv,{
	b:'prereq0:',  //':' indicates has arg
	c:'prereq1'
});

$.main('default');

//command.js -b Hello -c --prereq2=World
//->Hello true World
```

## Install CLI

```
sudo npm install -g recipe-js
```

## CLI Usage

```
@PARTPIPE@|dist/cli.js -h

!!SEE NPM README!!

@PARTPIPE@
```

## Change Log

- 0.4.0:(breaking change) using wildcard %  and regex for inference rules/file io
- 0.4.0:(breaking change) added -F option to cli for enable tracing (old -F option has been -f)
- 0.3.1:allows syntax like a '$.F([".html",".md"])'
- 0.3.0:added file IO
- 0.2.0:added Inference Rules
- 0.1.0:first release

