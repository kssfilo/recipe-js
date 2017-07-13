###jshint -W084###
###globals Promise###

class RecipeJs
	className:'RecipeJs'

	O:(m)->console.log "#{m}"
	T:(m)->console.log "#{@className}:T:#{m}" if @traceEnabled or @debugEnabled
	C:(m)->console.log "#{@className}:C:#{m}" if @debugEnabled
	E:(m)->console.error "Error:#{m}"

	constructor:(g={})->
		@_tasks={}
		@_objs={}
		@_running={}
		@_cache={}
		@_schedules={}
		@_timerHandle=null
		@_timeStamps={}
		{@parent,@extends,@traceEnabled,@debugEnabled,@traceScheduler}=g
		@set k,v for k,v of g.set if g.set?
	
	_normalizeTarget:(obj)->
		if obj.indexOf('%')>=0
			obj=obj.replace /\./g,'\.'
			obj=obj.replace /%/g,'(.+)'
		obj
	_normalizePrerequisite:(obj)->
		count=1
		obj.replace /%/g,(m,o,s)=>"$#{count++}"

	R:(obj,args...)->
		obj=@_normalizeTarget obj

		if args.length is 1 and typeof(args[0]) not in ['function','object']
			@C "set:#{obj}=#{args[0]}"
			@set obj,args[0]
			return
		
		prerequisites=null
		if args.length>=2 or typeof(args[0]) isnt 'function'
			if args[0] instanceof Array
				prerequisites=args.shift()
				prerequisites=prerequisites.map (x)=>@_normalizePrerequisite x
			else if typeof(args[0]) is 'string'
				prerequisites=@_normalizePrerequisite args.shift()

		func=null
		if typeof(args[0]) is 'function'
			func=args.shift()

		@C "task:#{obj},[#{prerequisites}]"
		
		@_tasks[obj]=
			obj:obj
			prerequisites:prerequisites
			func:func

	cache:(obj,v,expireSeconds=null)->
		cacheObj=
			v:v
			expire:if expireSeconds? then new Date().getTime()+expireSeconds*1000 else null
			updated:new Date().getTime()
		
		@_cache[obj]=cacheObj
		v

	set:(obj,value)->
		@C "set:#{obj},#{value},#{typeof value}"
		@_tasks[obj]=
			obj:obj
			value:value

	get:(obj)->
		return @_objs[obj] if @_objs[obj]?
		return @_tasks[obj].value if @_tasks[obj]?.value?

		if (c=@getCache obj) isnt null
			return @_objs[obj]=c

		target=@
		while target.extends?
			target=target.extends
		if target.parent?
			return target.parent.get obj
		else
			return null

	remake:(obj)->
		@_objs={}
		@_timeStamps={}
		@make obj

	getPrerequisites:(task)->
		t=task
		prerequisites=[]
		if typeof(t.prerequisites) is 'string'
			prerequisites.push t.prerequisites
		else if t.prerequisites instanceof Array
			prerequisites=t.prerequisites
		prerequisites

	getTimeStamp:(obj,stack=[])->
		@C "Checking timestamp of '#{obj}'"

		if t=@_timeStamps[obj]
			@C "timestamp:#{obj}:#{t}"
			return t

		updated=0
		if c=@_cache[obj]
			updated=c.updated ? 0
			now=new Date().getTime()
			if c.expire and c.expire<now
				@C "#{obj} has cache,but expired(left:#{(c.expire-now)/1000})"
				updated=-1

			@C "#{obj} has cache(timestamp:#{(updated-now)/1000}/left:#{(c.expire-now)/1000}})"
			return updated if c.expire is null and !c.checkDepends

		return updated if updated is -1

		###
		if @get(obj)?
			return @_timeStamps[obj]=0
		###

		if t=@searchTask obj
			@C "Checking prerequisites of '#{obj}'"
			prs=@getPrerequisites t
			for i in prs
				pt=@getTimeStamp i
				if pt is -1
					updated=-1
					break
				if pt>updated
					updated=-1

		@C "updated '#{obj}' s timestamp is #{updated}"
		return @_timeStamps[obj]=updated

	getCache:(obj,stack=[])->
		if c=@_cache[obj]
			ts=@getTimeStamp obj,stack
			if ts isnt -1
				@T "#{obj}(cached#{if c.expire? then ":"+(c.expire-new Date().getTime())/1000 else ''})"
				return @_cache[obj].v
			else
				@T "#{obj}(needs update)"
				delete @_cache[obj]
				delete @_objs[obj] if @_objs[obj]?
				@_tasks[obj].v=null if @_tasks[obj]?
		null

	searchTask:(obj)->
		t=@_tasks[obj]
		unless t?
			target=@
			while target.extends?
				target=target.extends
				if target._tasks[obj]?
					t=target._tasks[obj]
					break

			unless t?
				m=null
				regex=null
				for k,v of @_tasks
					regex=new RegExp "^#{k}$"
					if m=obj.match regex
						t=v
						break

				if t?
					@C "making new task from abstruct task:.#{k}"

					prerequisites=[]
					makeRealId=(regex,target,prereq)->target.replace regex,prereq

					if typeof(t.prerequisites) is 'string'
						prerequisites=makeRealId regex,obj,t.prerequisites
					else if t.prerequisites instanceof Array
						prerequisites=(makeRealId(regex,obj,i) for i in t.prerequisites)
					@R obj,prerequisites,t.func
					return @searchTask obj
		t

	make:(obj,stack=[])->
		@C "make #{obj},stack:[#{stack}]"

		if h=@get(obj)?
			@C "has #{obj}=#{h}"
			return Promise.resolve h

		t=@searchTask obj

		unless t?
			if @parent?
				return @parent.make obj,stack

			target=@
			while target.extends?
				target=target.extends
				if target.parent?
					return target.parent.make obj,stack

			return Promise.reject "No recipe:'#{obj}'"

		if stack.indexOf(obj)>=0
			throw "Loop:#{obj},[#{stack}]"

		prerequisites=@getPrerequisites t

		px=[]
		for i in prerequisites
			unless @get(i)
				if @_running[i]
					@C "#{obj}<=#{i}(RUNNING)"
					px.push @_running[i]
				else
					@C "#{obj}<=#{i}"
					stack.unshift obj
					px.push(@make i,stack)
					stack.shift()

		@_running[obj]=Promise.all px
		.then =>
			@C "finished processing prerequisites of #{obj}"
			@C "current running tasks [#{i for i of @_running}]"

			if @get(obj)
				@C "Skip:#{obj}(#{@get[obj]})"
				return

			rs=null
			recipeInfo=
				target:obj
				deps:t.prerequisites
			if typeof(t.prerequisites) is 'string'
				rs=@get(t.prerequisites)
				recipeInfo['dep']=t.prerequisites
			else if t.prerequisites instanceof Array and t.prerequisites.length>0
				#rs=(@get(i) for i in t.prerequisites)
				rs=[]
				for i in t.prerequisites
					v=@get i
					rs.push v
					rs[i]=v
			else
				rs=obj

			@T "#{obj}<-[#{JSON.stringify t.prerequisites}]"

			if t?.func? and typeof(t.func) is 'function'
				r=t.func.call @,rs,recipeInfo
			else
				r=rs
			unless r? and typeof(r.then) is 'function'
				@_objs[obj]=r
				delete @_running[obj] if @_running[obj]?
				return r
			else
				r.then (r2)=>
					@_objs[obj]=r2
					delete @_running[obj] if @_running[obj]?
					r2

		.catch (rs)=>
			delete @_running[obj] if @_running[obj]?
			#@E rs
			throw rs

	schedule:(time,obj,id=null)->
		id=id ? obj
		schedule=
			obj:obj
			enabled:true
		if typeof time is 'number'
			schedule.span=Math.abs time
			schedule.lastTime=if time<0 then new Date().getTime() else 0
		else if m=time.match /^(\d+)$/
			schedule.span=parseInt time
			schedule.lastTime=new Date().getTime()
		else if m=time.match /^(\d+):(\d+)$/
			schedule.timeOfDay=(parseInt(m[1])*60+parseInt(m[2]))*60*1000
		else if m=time.match /^\+(\d+)$/
			schedule.oneShot=(new Date().getTime()+parseInt(m[1]*1000))
		else
			schedule.oneShot=new Date(time).getTime()

		@_schedules[id]=schedule

		@C "schedule: #{JSON.stringify schedule}"

	enableSchedule:(id,isEnabled)->
		@_schedules[id].enabled=isEnabled
		true

	clearSchedule:(id)->
		delete @_schedules[id]
		
	run:(obj=null)->
		new Promise (rs,rj)=>
			lastTick=new Date().getTime()

			@_timerHandle=setInterval =>
				ids=(i for i of @_schedules)
				if ids.length is 0
					clearInterval @_timerHandle
					@_timerHandle=null
					if obj?
						if r=@get obj
							rs r
						else
							rj 'failed'
					else
						rs null

				now=new Date().getTime()
				offset=new Date().getTimezoneOffset()*60000
				timeOfDay=(now-offset)%(24*3600*1000)
				lastTimeOfDay=(lastTick-offset)%(24*3600*1000)
				lastTimeOfDay-=24*3600*1000 if lastTimeOfDay>timeOfDay
				#@C "schedule: #{JSON.stringify @_schedules}"
				@C "scheduler:[#{ids}]" if @traceScheduler
				for id,i of @_schedules
					continue unless i.enabled
					if i.oneShot?
						@C "oneShot:#{now} >= #{i.oneShot} > #{lastTick}" if @traceScheduler
						if now>=i.oneShot>lastTick
							@remake i.obj
							@clearSchedule id
					else if i.timeOfDay?
						@C "timeOfDay:#{((now-offset)%(24*3600*1000))},>=#{i.timeOfDay}>#{((lastTick-offset)%(24*3600*1000))})" if @traceScheduler
						if ((now-offset)%(24*3600*1000))>=i.timeOfDay>((lastTick-offset)%(24*3600*1000))
							@remake i.obj
					else if i.span?
						@C "span:#{now-i.lastTime}>=#{i.span*1000}" if @traceScheduler
						if (now-i.lastTime)>=i.span*1000
							i.lastTime=now
							@remake i.obj
				lastTick=now
			,1000

class RecipeNodeJs extends RecipeJs
	className:'RecipeNodeJs'

	constructor:(g={})->
		super g

		if g.cacheFile and not g.clearCache
			{@cacheFile}=g
			@loadCache()

		@_files={}
		@_saveFiles={}

	loadCache:->
		try
			t=require('fs').readFileSync @cacheFile
			@_cache=JSON.parse t
			@C "cacheFile:#{t}"
		catch
			@C 'cacheFile:not found'
			@_cache={}

	saveCache:->
		for k,v of @_cache
			if v.isFile
				delete @_cache[k]

		return unless @cacheFile?
		@C "saveCache:#{JSON.stringify @_cache}"
		require('fs').writeFileSync @cacheFile,JSON.stringify @_cache

	S:(cmd,input=null)->
		@C "S: #{cmd}, #{input}"
		ca=cmd.match(/[^\s'"|]+|'[^']+'|"[^"]+"|\|/g)

		if ca.indexOf('|')>=0
			cmds=[]
			while (i=ca.indexOf('|'))>=0
				c1=ca.splice(0,i)
				@C c1
				ca.shift()
				@C ca
				#cmds.push c1.map((x)->"'#{x}'").join(' ')
				cmds.push c1.join(' ')

			#cmds.push ca.map((x)->"'#{x}'").join(' ')
			cmds.push ca.join(' ')
			@C "SPLIT:"+cmds

			cmdArray=[]
			start=@S(cmds.shift(),input)

			while c=cmds.shift()
				cmdArray.push @P(c)

			return cmdArray.reduce ((x,y)->x.then y),start

		new Promise (ok,ng)=>

			ca=ca.map (x)->x.replace(/^"(.*)"$/,'$1').replace(/^'(.*)'$/,'$1')
			@C JSON.stringify ca
			out=''
			err=''
			instream=if input? then 'pipe' else process.stdin
			c=require('child_process').spawn ca.shift(),ca,
				stdio:[instream,'pipe','pipe']

			if input?
				do (i=c.stdin)->
					i.setEncoding 'utf-8'
					i.write input
					i.end()

			c.stdout.on 'data',(d)->out+=d
			c.stderr.on 'data',(d)->err+=d
			c.on 'close',(code)->
				if code isnt 0
					ng err
				else
					ok out

	P:(cmd)->
		(x)=>@S cmd,x

	F:(extentionOrFilenameOrArray)->
		if extentionOrFilenameOrArray instanceof Array
			@_files[@_normalizeTarget i]=true for i in extentionOrFilenameOrArray
		else
			@_files[@_normalizeTarget extentionOrFilenameOrArray]=true
		null
	
	setByArgv:(args,dict=null)->
		remaining=[]
		j=0
		while i=args[j++]
			switch
				when c=i.match /^-(.)$/
					if actual=dict?[c[1]]
						hasValue=actual.match /:$/
						actual=actual.replace /:$/,''
						if hasValue? and j<args.length
							value=args[j++]
						else if !hasValue?
							value=true

						value=parseInt value if typeof(value) is 'string' and value.match /^\d+$/
						@set actual,value

				when c=i.match /^--(.*)=(.*)$/
					value=c[2]
					value=parseInt value if typeof(value) is 'string' and value.match /^\d+$/
					@set(c[1],value)

				when c=i.match /^--([^=]*)$/
					@set(c[1],true)
				else
					remaining.push i

		remaining

	isFile:(obj)->
		return true if @_files[obj]?
		r=false
		for k of @_files
			regex=new RegExp "^#{k}$"
			if m=obj.match regex
				r=true
				break
		r
	
	getTimeStamp:(obj,stack=[])->
		if !@_cache[obj]? and @isFile(obj)
			@C "'#{obj}' is a file, check filesystem"
			try
				stat=require('fs').statSync obj
				@_cache[obj]=
					v:require('fs').readFileSync(obj)?.toString()
					updated:new Date(stat.mtime).getTime()
					expire:null
					checkDepends:true
			catch
				@C "'#{obj}' does't exist, try to make"
				return -1

		super obj,stack

	getCache:(obj,stack=[])->
		if !@_cache[obj]? and @isFile(obj)
			ts=@getTimeStamp obj,stack
			@C "#{obj},#{ts}"

			if ts isnt -1 and ts<=new Date().getTime()
				return @_cache[obj].v
			else
				@C "mark to save :#{obj}"
				@_saveFiles[obj]=true
				null
		else
			super obj,stack

	saved:(t)->
		return (g)=>
			delete @_saveFiles[t.target]
			require('fs').readFileSync t.target

	save:(t)->
		return (g)=>
			require('fs').writeFileSync t.target,g
			delete @_saveFiles[t.target]
			g

	make:(obj,stack=[])->
		super obj,stack
		.then (g)=>
			if @_saveFiles[obj]
				@C "saveFile:#{obj}"
				require('fs').writeFileSync obj,g
				delete @_saveFiles[obj]
			g

	main:(objOrArray,arrayTarget=null)->
		try
			if objOrArray instanceof Array
				Promise.all(objOrArray.map((x)->x.make arrayTarget))
				.then (xs)=>
					@O xs if xs?
					objOrArray.forEach (x)->x.saveCache()
					process.exit 0
				.catch (e)=>
					@E e
					process.exit 1
			else
				@make objOrArray
				.then (x)=>
					@saveCache()
					process.exit 0
				.catch (e)=>
					@E e
					process.exit 1
		catch e
			@E e


module.exports={
	RecipeJs
	RecipeNodeJs
}
