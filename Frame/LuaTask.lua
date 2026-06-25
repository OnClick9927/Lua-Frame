---@class TaskAWaiter:LuaType
local TaskAWaiter = class("TaskAWaiter")
function TaskAWaiter:ctor()
    self.IsCompleted = false
    self.Packaged = false
    self.actions = {}
end

function TaskAWaiter:GetException()
    return self.exception
end

function TaskAWaiter:GetResult()
    if not self.IsCompleted then
        error("The task is not finished yet")
    end
    if self.exception then
        error(self.exception)
    end

    return self.result
end

function TaskAWaiter:SetResult(result, exception, packaged)
    if exception then
        self.exception = exception
    else
        self.result = result
    end

    self.IsCompleted = true
    self.Packaged = packaged

    if not self.actions then
        return
    end

    for _, v in pairs(self.actions) do
        if v then
            xpcall(
                v,
                function(err)
                    err("%s \n%s", err, debug.traceback())
                end
            )
        end
    end
end

function TaskAWaiter:OnCompleted(action)
    if not action then
        return
    end

    if self.IsCompleted then
        xpcall(
            action,
            function(err)
                err("%s \n%s", err, debug.traceback())
            end
        )
        return
    end

    table.insert(self.actions, action)
end

---@class LuaTask:TaskAWaiter
LuaTask = class("LuaTask", TaskAWaiter)

--- 模拟异步 方法
---@param action function
---@return function
function async(action)
    return function(...)
        local task = LuaTask()
        if type(action) ~= LuaDataType.Function then
            task:SetResult(nil, "please enter a function")
            return task
        end

        local co =
            coroutine.create(
                function(...)
                    local results =
                        table.pack(
                            xpcall(
                                action,
                                function(err)
                                    task:SetResult(nil, err, false)
                                    err("%s \n%s", err, debug.traceback())
                                end,
                                ...
                            )
                        )

                    local status = results[1]
                    if status then
                        table.remove(results, 1)
                        if #results <= 1 then
                            task:SetResult(results[1], nil, false)
                        else
                            task:SetResult(results, nil, true)
                        end
                    end
                end
            )
        coroutine.resume(co, ...)
        return task
    end
end

--- 模拟异步 等待方法 只能在 async 里面调用
---@param result TaskAWaiter
function await(result)
    assert(result ~= nil, "The result is nil")
    local status, awaiter

    if type(result) == LuaDataType.Table and Tools.IsSubClassOf(Tools.GetClassType(result), TaskAWaiter) then
        awaiter = result
    elseif type(result) == LuaDataType.UserData or type(result) == LuaDataType.Table then
        status, awaiter = pcall(result.GetAwaiter, result)
        if not status then
            error("The parameter of the await() is error,not found the GetAwaiter() in the " .. tostring(result))
        end
    else
        error("The parameter of the await() is error, this is a function, please enter a table or userdata")
    end

    if awaiter.IsCompleted then
        local value = awaiter:GetResult()
        if type(value) == LuaDataType.Table and awaiter.Packaged then
            return table.unpack(value)
        else
            return value
        end
    end

    local id = coroutine.running()
    local isYielded = false
    awaiter:OnCompleted(
        function()
            if isYielded then
                coroutine.resume(id)
            end
        end
    )

    if not awaiter.IsCompleted then
        isYielded = true
        coroutine.yield()
    end

    local value = awaiter:GetResult()
    if type(value) == "table" and awaiter.Packaged then
        return table.unpack(value)
    else
        return value
    end
end

---@return LuaTask
function LuaTask.Delay(second)
    local task = LuaTask()
    Tools.SetTimeout(function(_)
        _:SetResult(true)
    end, second, task)
    return task
end

---@return LuaTask
function LuaTask.Run(func, ...)
    local action = async(func)
    return action(...)
end
