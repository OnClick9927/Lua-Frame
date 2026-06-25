---@class ValueContainer
ValueContainer = class("ValueContainer")
function ValueContainer:ctor()
    ---@type table<string,table|boolean>
    self.Type_map = {}
    self.Container = {}
end

---@param _type LuaType
---@param ... LuaType
function ValueContainer:SetValueFunc(_type, ...)
    self:SetValueAsFunc(_type, _type, ...)
end

---@param _baseType LuaType 注入类型
---@param _type LuaType 实际类型
---@param ... LuaType  构造实际类型时，需要的类型
function ValueContainer:SetValueAsFunc(_baseType, _type, ...)
    if not Tools.IsAssignableFrom(_type, _baseType) then
        error(_type.__clsName .. " is not " .. _baseType.__clsName)
        return
    end
    if ... then
        self.Type_map[_baseType.__clsName] = {
            realType = _type,
            params = { ... }
        }
    else
        self.Type_map[_baseType.__clsName] = {
            realType = _type,

        }
    end
end

---@param _type LuaType 需求的类型
---@param ... any 其他参数
---@return table|nil
function ValueContainer:GetValue(_type, ...)
    local clsName = _type.__clsName
    local result = self.Container[clsName]
    if result then
        return result
    end
    local args = self.Type_map[clsName]
    if not args then
        return nil
    end
    local params = args.params
    local realType = args.realType

    if params == nil then
        result = realType(...)
    else
        local _params = {}

        for index, value in ipairs(params) do
            local dp = self:GetValue(value)
            if dp == nil then
                error("not found " .. value.__clsName)
            end
            table.insert(_params, dp)
        end
        if ... then
            local tab = { ... }
            for i = 1, #tab, 1 do
                table.insert(_params, tab[i])
            end
        end
        result = realType(table.unpack(_params))
    end
    self.Container[clsName] = result
    return result
end

---@param instance table
---@param asType LuaType|nil
function ValueContainer:SetValueAs(instance, asType)
    local _type = Tools.GetClassType(instance)
    if asType == nil then
        asType = _type
    else
        if not Tools.IsAssignableFrom(_type, asType) then
            if _type then
                error(_type.__clsName .. " not fit " .. asType.__clsName)
            else
                error("instance is not instance")
            end
            return
        end
    end
    self.Container[asType.__clsName] = instance
end
