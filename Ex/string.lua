string.empty = ""
function string.IsNullOrEmpty(source)
    return source == nil or source == string.empty
end

---去除头部空格
---@param  source string
---@return string
function string.TrimHead(source)
    return string.gsub(source, "^[ \t\n\r]+", string.empty)
end

--- 去除输入字符串尾部的空白字符，返回结果
---@param  source string
---@return string
function string.TrimTail(source)
    return string.gsub(source, "[ \t\n\r]+$", string.empty)
end

--- 去除输入字符串 尾部+头部 的空白字符，返回结果
---@param  source string
---@return string
function string.Trim(source)
    source = string.TrimHead(source)
    return string.TrimTail(source)
end

--- 将字符串的第一个字符转为大写，返回结果
---@param  source string
---@return string
function string.UpperFirst(source)
    return string.upper(string.sub(source, 1, 1)) .. string.sub(source, 2)
end

---用指定字符或字符串分割输入字符串，返回包含分割结果的数组
---@param source string 源字符串
---@param delimiter string 分割符
---@return string[]
function string.Split(source, delimiter)
    source    = tostring(source)
    delimiter = tostring(delimiter)
    if string.IsNullOrEmpty(delimiter) then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(source, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(source, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(source, pos))
    return arr
end

-- 计算 UTF8 字符串的长度，每一个中文算一个字符
-- local input = "你好World"
-- string.UTF8Length(input)
-- 输出 7
---@param  source string
---@return number
function string.UTF8Length(source)
    local len = string.len(source)
    local left = len
    local cnt = 0
    local arr = { 0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
    while left ~= 0 do
        local tmp = string.byte(source, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end
