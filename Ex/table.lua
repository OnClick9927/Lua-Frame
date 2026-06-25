--- 深拷贝一个table
---@param t table
---@return table
function table.DeepCopy(t)
    local SearchTable = {}
    local function Func(object)
        if type(object) ~= LuaDataType.Table then return object end
        local NewTable = {}
        SearchTable[object] = NewTable
        for k, v in pairs(object) do
            NewTable[Func(k)] = Func(v)
        end
        return setmetatable(NewTable, getmetatable(object))
    end

    return Func(t)
end

--- 清空一个Table
---@param t table
function table.Clear(t)
    for _, v in pairs(t) do t[v] = nil end
end

--- 计算表格包含的字段数量
--- Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。
---@param t table
---@return number
function table.GetCount(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

--- 返回指定表格中的所有键
--- local hashtable = {a = 1, b = 2, c = 3}
--- local keys = table.GetKeys(hashtable)
--- keys = {"a", "b", "c"}
---@param hashtable table
---@return any[]
function table.GetKeys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

---@param hashtable table
---@param key string
---@return boolean
function table.ContainsKey(hashtable, key)
    local t = type(hashtable)
    return (t == LuaDataType.Table or t == LuaDataType.UserData) and hashtable[key] ~= nil
end

--- 返回指定表格中的所有值
--- local hashtable = {a = 1, b = 2, c = 3}
--- local values = table.GetValues(hashtable)
--- values = {1, 2, 3}
---@param hashtable table
---@return any[]
function table.GetValues(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

--- 将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值
--- local dest = {a = 1, b = 2}
--- local src  = {c = 3, d = 4}
--- table.merge(dest, src)
--- dest = {a = 1, b = 2, c = 3, d = 4}
---@param dest table
---@param src table
function table.Merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--- 在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格
--- local dest = {1, 2, 3}
--- local src  = {4, 5, 6}
--- table.Insert(dest, src)
--- dest = {1, 2, 3, 4, 5, 6}
--- dest = {1, 2, 3}
--- table.Insert(dest, src, 5)
--- dest = {1, 2, 3, nil, 4, 5, 6}
---@generic V
---@param dest V[]
---@param src V[]
---@param begin number
function table.Insert(dest, src, begin)
    local bo, begin = math.RoundToInt(begin)
    if not bo then
        begin = 0
    end
    if begin <= 0 then
        begin = #dest + 1
    end
    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

---@param tab table
---@param value any
function table.GetKey(tab, value)
    for index, _value in pairs(tab) do
        if _value == value then
            return index
        end
    end
    return false
end

---筛选所有符合条件的数据
---@generic K
---@generic V
---@param tab table<K,V>
---@param ... fun(a:V):boolean
---@param return_dic boolean 返回值是否采用原有的key
---@return table<K,V>|V[]
function table.FindAll(tab, return_dic, ...)
    local result = {}
    for key, value in pairs(tab) do
        local bo = Tools.FitConditions(value, ...)
        if bo then
            if return_dic then
                result[key] = value
            else
                table.insert(result, value)
            end
        end
    end
    return result
end

---筛选第一个符合条件的数据
---@generic K
---@generic V
---@param tab table<K,V>
---@param ... fun(a:V):boolean
---@return V
function table.Find(tab, ...)
    for key, value in pairs(tab) do
        local bo = Tools.FitConditions(value, ...)
        if bo then
            return value
        end
    end
end

--- 对表格中每一个值执行一次指定的函数，并用函数返回值更新表格内容
---@generic K,V
---@param t table<K,V>
---@param func fun(key:K,Value:V):V
function table.Map(t, func)
    for k, v in pairs(t) do
        t[k] = func(k, v)
    end
end

--- 对表格中每一个值执行一次指定的函数
---@generic K,V
---@param t table<K,V>
---@param func fun(key:K,Value:V)
function table.Walk(t, func)
    for k, v in pairs(t) do
        func(k, v)
    end
end

--- 对表格中每一个值执行一次指定的函数，如果该函数返回 true，则对应的值会从表格中删除
---@generic K,V
---@param t table<K,V>
---@param func fun(key:K,value:V):boolean
function table.RemoveAll(t, func)
    for k, v in pairs(t) do
        if func(k, v) then
            t[k] = nil
        end
    end
end

---遍历表格，确保其中的值唯一
---@generic V
---@param t table
---@param bArray boolean 是否转成数组
---@return table<any,V>|V[]
function table.Distinct(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

---判断一个table 是不是 空的
---@param table table
---@return boolean
function table.IsEmpty(table)
    return not next(table)
end

---反转table
---@generic V
---@param array V[]
---@return V[]
function table.Reverse(array)
    local var = {}
    for i = 1, #array do
        var[i] = table.remove(array)
    end
    return var
end

---交换俩个元素
---@param array table
---@param i any
---@param j any
function table.Swap(array, i, j)
    if i and j and not table.IsEmpty(array) then
        local tmp = array[i]
        array[i] = array[j]
        array[j] = tmp
    end
end

function table.IndexOf(tab, entity)
    for i, v in pairs(tab) do
        if entity == v then
            return i
        end
    end
end

---多条件排序 第一个条件无法判断就判断后一个
---@generic V
---@param list V[]
---@param ... fun(a:V, b:V):number 比较下一个0 ;成立 1;不成立-1
function table.Sort(list, ...)
    local args = { ... }
    if table.IsEmpty(args) then
        return
    end
    local compare = function(a, b)
        for _, condition in ipairs(args) do
            local _result = condition(a, b)
            if _result > 0 then
                return true
            elseif _result < 0 then
                return false
            end
        end
        return false
    end
    table.sort(list, compare)
end

---转化一个table
---@generic K
---@generic V
---@generic Convert
---@param tab table<K,V>
---@param func fun(a:V):Convert
---@param return_dic boolean
---@return table<K,Convert>|Convert[]
function table.Convert(tab, func, return_dic)
    local result = {}
    for key, value in pairs(tab) do
        local convert = func(value)
        if return_dic then
            result[key] = convert
        else
            table.insert(result, convert)
        end
    end
    return result
end
