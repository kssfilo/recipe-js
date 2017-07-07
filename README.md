recipe-js
==========

GNU make like task launcher.Supports prerequisites/Promise/child process/cache/deriving/CLI.

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

- 0.1.x:first release
