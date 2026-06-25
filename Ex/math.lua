---对数值进行四舍五入
---@param value number 数值
---@return number
function math.RoundToInt(value)
    return math.floor(value + 0.5)
end

---对数值进行取小数部分
---@param value number 数值
---@return number
function math.Frac(value)
    return value - math.floor(value)
end

---角度转弧度
---@param angle number 角度
---@return number
function math.AngleToRadian(angle)
    return angle * math.pi / 180
end

---弧度转角度
---@param radian number 弧度
---@return number
function math.RadianToAngle(radian)
    return radian / math.pi * 180
end