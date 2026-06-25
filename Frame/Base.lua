--- @enum LuaDataType Lua数据类型枚举
LuaDataType = {
    Number   = "number",
    String   = "string",
    Nil      = "nil",
    Boolean  = "boolean",
    Function = "function",
    Table    = "table",
    UserData = "userdata",
    Thread   = "thread"
}
Tools = {}
---判断一个值能否通过条件
---@generic V
---@param value V
---@param ... fun(a:V):boolean
---@return boolean
function Tools.FitConditions(value, ...)
    local args = { ... }
    for _, func in ipairs(args) do
        local bo = func(value)
        if not bo then
            return false
        end
    end
    return true
end

-- 生成方法句柄
--- @param method function 类型名称
--- @return function
function Tools.Handler(method, ...)
    local args = { ... }
    if table.IsEmpty(args) then
        return function(...)
            return method(...)
        end
    else
        return function(...)
            local args2 = { ... }
            if table.IsEmpty(args2) then
                return method(table.unpack(args))
            else
                for i = #args, 1, -1 do
                    table.insert(args2, 1, args[i])
                end
                return method(table.unpack(args2))
            end
        end
    end
end

function Tools.Lock_G()
    if _G.__locked then return end
    local meta = {}
    meta.__newindex = function(_, k, v) error("attempt to add a new value to global,key: " .. k, 2) end
    -- meta.__index = function(_, k)
    --     return rawget(_, k) or rawget(_.UsingStaticTable, k)
    -- end
    _G.__locked = true
    setmetatable(_G, meta)
end

---@class TryBlock
---@field catch function
---@field finally function

---C# try
---@param block TryBlock
function try(block)
    local main = block[1]
    local catch = block.catch
    local finally = block.finally

    local results = table.pack(pcall(main))
    local status = results[1]
    local e = results[2]
    table.remove(results, 1)
    local result = results
    local catched = false
    if (not status) and catch and type(catch) == LuaDataType.Function then
        catched = true
        local results = table.pack(pcall(catch, e))
        if results[1] then
            table.remove(results, 1)
            result = results
            e = nil
        else
            e = results[2]
        end
    end

    if finally and type(finally) == LuaDataType.Function then
        pcall(finally)
    end

    if status then
        return table.unpack(result)
    elseif catched then
        if not e then
            return table.unpack(result)
        else
            error(e)
        end
    else
        error(e)
    end
end

local timers = {}

function Tools.SetTimeout(callback, delay, ...)
    local expire = os.time() + delay
    table.insert(timers, {
        callback = Tools.Handler(callback, ...),
        expire = expire
    })
end

-- 在每一帧/循环中调用 UpdateTimers()
function Tools.UpdateTimers()
    local now = os.time()
    for i = #timers, 1, -1 do
        if timers[i].expire <= now then
            local cb = timers[i].callback
            table.remove(timers, i)
            cb()
        end
    end
end

