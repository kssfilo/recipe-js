recipe-js
==========

A gulp/GNU make like task launcher with CLI tool.Supports Dependencies/Cache/Inference Rules/Promise/Child Process/Deriving/Scheduler

- [npmjs(document)](https://www.npmjs.com/package/recipe-js)
- [GitHub(bug report)](https://github.com/kssfilo/recipe-js)
- [Home Page](https://kanasys.com/gtech/673)

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
//$.R(targetName,[prerequisite,prerequisite...],callback) # declares "recipe" of "targetName"
//$.set(target,value) # declares target is value
//$.make(targetName) # make target
//$.remake(takgetName) # clear cache then re-make target
```

recipe-js is GNU make like task launcher. unlike normal program sequence, recipe-js 'resolves' prerequisites of the target then gathers these task's results automatically.

you can 'declare' task by $.R function or $.set functtion like above example. $.R are function tasks which getting their prerequisites vir argument('g' above) then return result as 'targetName'

'g' argument is just an object which has attributes. the name of attributes is same as the prerequisite name.

.set() is just assigning a value to the target name, unlike .R, that has no function task.

.make() returns promise() with result of target task. so above example means like :  'default' needs 'prereq0' and 'prereq1', 'prereq0' is hello, 'prereq1' will be World after 1 sec later. so 'default' is string hello + World. .make() gets this result and print at .then().

recipe-js caches each result of tasks in memory. so same task will never be called if a prerequisite are used 2 or more times. 

you can call .remake(targetName) instead of .make(), the internal cache is cleared for refreshing results or need side-effect of task again.

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

$.make('default');

//-> Hello Mr.username
//$.S(cmd) execute shell command as promise. able to inject stdin(as string) via 2nd argument
//$.P(cmd) is short hand for (stdin)=>$.S(cmd,stdin)
```
There are 2 classes are exported recipe-js module. RecipeJs class and RecipeNodeJs class. RecipeJS class doesn't access NodeJs API such as FileIO(fs) or child\_process.

RecipeNodeJs class os derived from Recipe.Js class. this class has  Nodejs feature. so basically, you should use RecipeNodeJs class.

.S() and .P() are process execution tasks. you can easy to write and receive external tool's results such as curl without having to write complex child\_process programs.

you can pass data into stdin by a 2nd argument of .S().  off course you can use pipe | inside command line string.  execution is asynchronous.

### Inference Rules

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

like GNU make. recipe-js have inference Rules. you can declare .R() which have wildcard (%) or regex.

### File IO(auto load/save)

```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs(); 

// $.F tells that specified targets(extension/filename) are files.
$.F('%.md');
$.F('%.html');

$.R('%.html','%.md',$.P('md2html'));

$.R('default',['prereq0.html']);

$.make('default'); 
//-> file prereq0.md(# Hello) -> file prereq0.html (<h1>Hello</h1>) 
//file system's timestamp is used for update decision
```

.F() marks the target name as "file name". recipe-js automatically read the file even if there is no recipe for this name.

if marked target name is prerequisites or make() target, the file is generated and written by passed data.

target name for $.F can have wild card or regex.

### Cache / Trace / Debug
```
RecipeNodeJs=require('recipe-js').RecipeNodeJs;

$=new RecipeNodeJs({
	cacheFile:'MyCache.json'
	traceEnabled:true
	//debugEnabled:true
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

$.make('default'); 

//-> MyCache.json -> '{"prereq0":{"v":"user\n","expire":1499307137335}}'
//if you run this program again, 'whoami' will not be called till 180 sec later.
```
you can specify these options to constructor to see verbose output.

- traceEnabled:true
- debugEnabled:true //detail

results which enclosed by .cache() is saved to json file which specified in cacheFile option. 

the cache will automatically be loaded at next execute then use the cached value instead of execute $.R till expired time.

specifying 'cacheId' instead of 'cacheFile' makes JSON file at ~/.recipe-js/<cacheId>.json . ('cacheFile' is higher priority than 'cacheId'.)

a cache file is synced at end of each make() (including internal make for prerequisites)

```
$=new RecipeNodeJs({
	cacheFile:'MyCache.json'
});

count=0;
$.R('prereq0',()=>{
    $.cache('prereq0',`count:${count++}`,2); // 2sec
});

$.R('default','prereq0',(g)=>console.log(g));

$.make('default')
.then(()=>{
	// $.clearCache();  <- if you remove //  , then result will be 0,1,2
    setTimeout(()=>
        $.remake('default')
    ,1000);

    setTimeout(()=>
        $.remake('default')
    ,5000);
});
//->count:0
//  count:0 (from Cache)
//  count:1
```

.remake(target) method clears memory cache only. so tasks which returns .cache() are never called till expired time evenif .remake() call.

if you want to clear file cache, set 'clearCache:true' option at constructor. or call .clearCache() dynamically(never call this method inside task).

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

Deriving is useful when re-using common recipes. just specifying extends attribute to createing new RecipeJs class. The class will be child recipe.

if there are no recipe($.R) in child RecipeJs. parent $.R will be used.(override)

### Deriving (parent)

```
RecipeJs=require('./dist/recipe-js').RecipeJs;

parent=new RecipeJs();

parent.R('prereq0',()=>{
    return new Promise((ok)=>{
        setTimeout(()=>{
            ok('World');
        },10000);
    });
});

child1=new RecipeJs({
    parent:parent    //<-test left 'parent' to 'extends'
});

child1.R('default','prereq0',(g)=>{
    console.log(`Child1 ${g}`);
});

child2=new RecipeJs({
    parent:parent    //<-test left 'parent' to 'extends'
});

child2.R('default','prereq0',(g)=>{
    console.log(`Child2 ${g}`);
});

child1.make('default')
.then(()=>{
    child2.make('default');
});
//-> Child1 World (10sec after start)
//-> Child2 World (10sec after start because parent 'prereq0' result are re-used in parent object)
//   if you change like above comment, it will be 20 sec
```

unlike 'extends' deriving, 'parent' deriving is for sharing results by children.

this means that result objects are stored in parent object, not child object itself. so the object is able to access other child classes.

recipe-js caches each result of tasks in memory even if cacheFile option is not specified. so the same task will be never called till .remake(target) 

### Command line parser

```
$=new RecipeNodeJs();

$.R('default',['prereq0','prereq1','prereq2'],(g)=>{
	console.log(`${g.prereq0} ${g.prereq1} ${g.prereq2}`);
});

$.set('prereq0','-');  //defaults
$.set('prereq1',false);
$.set('prereq2','-');

remains=$.setByArgv(process.argv,{
	b:'prereq0:',  //':' indicates has arg
	c:'prereq1'
});

$.make('default');

//command.js -b Hello -c --prereq2=World
//->Hello true World
```

.setByArgv() is utility to set prerequisites by command line arguments.

recipe-js knows which relation between -option and target names and whether option arg e.g.(-b hello) are necessary or not.

--prereq=2=world style options sets target values directly.

### Scheduler

```
$=new RecipeJs({
    debugEnabled:true,
    traceScheduler:true  //show time tick on debug out
});

$.R('timer1',(g)=>{
    console.log("12 o'clock");
});

$.R('timer2',(g)=>{
    console.log("10sec passed");
});

$.R('timer3',(g)=>{
    console.log("60sec(one shot)");
	$.clearSchedule('scheduleid2); //turn of 10sec timer
});

$.schedule("12:00",'timer1');               //12:00 every day
$.schedule("10",'timer2','scheduleid2');    //every 10sec
$.schedule("+60",'timer3');                 //60sec after (one shot)
$.run();
```

you can use recipe-js as 'cron' server by .run() method of RecipeJs (off course RecipeNodeJs is also ok)

.schedule() schedules .remake() task. 1st arg is time(3 kind.see above example),2nd is target name, 3rd(optional) is id.

you can turn on / off shedule by .enableSchedule(id) / .clearSchedule(id). id is 3rd argument of .schedule()

### .main()

```
$=new RecipeNodeJs();

$.R('target',(g)=>{
    return Promise.resolve("Hello");
});

$.main('target');
```

.main is an utility method. you can use it like .make(). difference between .make() is print out result even if target doesn't console.log().

this is useful if the target recipe just returns value. 

if you pass an array of RecipeNodeJs() object in 1st arg and target name in 2nd arg, .main() invokes all of RecipeNodeJs to make the same target then wait complete by Promise.all, then print out collected results.

note that unlike .make(), .main doesn't return not promise() and process.exit() inside after print. 

## Install CLI

```
sudo npm install -g recipe-js
```

## CLI Usage

```
@PARTPIPE@|dist/cli.js -h

see https://www.npmjs.com/package/recipe-js

@PARTPIPE@
```

## Change Log

- 1.0.0:cacheId constructor option to save cache into ~/.recipe-js / supports shebang for Recipefile / scheduler
- 0.5.5:changed substitution '%'->'.+' to '%'->'[^.]+'.
- 0.5.4:added $.X(cmd) for shell execution(supports redirection but cant inject into stdin), $.PX(cmd) is shorthand of ()=>$.X(cmd)
- 0.5.3:added special target "TRACE"/"DEBUG" for Recipefile
- 0.5.0:added saved()/-D option
- 0.4.2:showing expiration of cache in trace output
- 0.4.1:added 'debugEnabled' option for constructor for debugging
- 0.4.1:fixed cache expiration problem
- 0.4.0:(breaking change) using wildcard %  and regex for inference rules/file io
- 0.4.0:(breaking change) added -F option to cli for enable tracing (old -F option has been -f)
- 0.3.1:allows syntax like a '$.F([".html",".md"])'
- 0.3.0:added file IO
- 0.2.0:added Inference Rules
- 0.1.0:first release

