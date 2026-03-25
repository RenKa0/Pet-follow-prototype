--!strict
export type Destructable = any

export type MaidTask = (() -> ()) | Instance | thread | Destructable | RBXScriptConnection | nil

local module = {}

function module.is_valid_task(job: any): boolean
	local jobType = typeof(job)
	return jobType == "function"
		or jobType == "thread"
		or jobType == "RBXScriptConnection"
		or jobType == "Instance"
		or (jobType == "table" and type(job.Destroy) == "function" and type(job.Disconnect) == "function")
end

function module.do_task(job: MaidTask): ()
	if typeof(job) == "function" then
		(job :: any)()
	elseif typeof(job) == "table" then
		if type(job.Destroy) == "function" then
			job:Destroy()
		elseif type(job.Disconnect) == "function" then
			job:Disconnect()
		end
	elseif typeof(job) == "Instance" then
		job:Destroy()
	elseif typeof(job) == "thread" then
		local cancelled
		if coroutine.running() ~= job then
			cancelled = pcall(function()
				task.cancel(job)
			end)
		end

		if not cancelled then
			task.defer(function()
				task.cancel(job)
			end)
		end
	elseif typeof(job) == "RBXScriptConnection" then
		job:Disconnect()
	else
		error(string.format("[MaidTaskUtils.doTask] - Bad job of type %q", typeof(job)))
	end
end

function module.do_list(jobs: {MaidTask})
	for _, job in jobs do
		module.do_task(job)
	end
end

function module.delayed(time: number, job: MaidTask): () -> ()
	assert(type(time) == "number", "Bad time")
	assert(module.is_valid_task(job), "Bad job")

	return function(): ()
		task.delay(time, function()
			module.do_task(job)
		end)
	end
end

return module