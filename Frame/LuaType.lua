---@class LuaType:table
---@field __clsName string
---@field __interfaces table<LuaType>|nil

local interface_meta = {
    __call = function(_type) error("this is a interface " .. _type.__clsName) end,
}
local types = {}
---@enum TableType
TableType = {
    None = "None",
    Type = "Type",
    Instance = "Instance",
    interface = "interface",
}
local interface_check = {}

local function CallCtor(instance, _type, ...)
    local super = getmetatable(_type).__index
    if super then CallCtor(instance, super, ...) end
    local ctor = rawget(_type, "ctor")
    if ctor then ctor(instance, ...) end
    return instance
end
local function IsRealizeInterface(_type, __interface)
    for key, value in pairs(__interface) do
        if key ~= "__clsName" and not _type[key] then
            return false,
                _type.__clsName .. " not realize " .. __interface.__clsName .. "." .. key .. "(" .. type(value) .. ")"
        end
    end
    return true
end


---@param _type LuaType
local function CheckTypeInterfaces(_type)
    local name = _type.__clsName
    local result = interface_check[name]
    if result == true then return true end
    if result == false then return false end
    result = true
    local __interfaces = _type.__interfaces
    if __interfaces then
        for _, __interface in ipairs(__interfaces) do
            local success, message = IsRealizeInterface(_type, __interface)
            if not success then
                error(message)
                result = false
            end
        end
    end
    interface_check[name] = result
    return result
end
local function CreateInstance(_type, ...)
    local instance        = {}
    local instance_meta   = {}
    instance_meta.__index = _type
    instance_meta.__call  = function(_, ...) error("this is a Instance of " .. _.__clsName) end
    CheckTypeInterfaces(_type)
    setmetatable(instance, instance_meta)
    return CallCtor(instance, _type, ...)
end

local function ExpandInterfaces(interfaces, result)
    if not interfaces then return end
    for index, _interface in ipairs(interfaces) do
        ExpandInterfaces(_interface.__interfaces, result)
        table.insert(result, _interface)
    end
    return result
end

local function CreateType(cls, name, super, ...)
    if types[name] then error("type " .. name .. " already exist") end
    local clsType = {}
    types[name] = clsType
    clsType.__clsName = name
    if ... then clsType.__interfaces = ExpandInterfaces({ ... }, {}) end
    local meta = cls and {} or interface_meta
    if cls then
        meta.__index = super
        meta.__call = CreateInstance
    end
    setmetatable(clsType, meta)
    return clsType
end
---@generic T:LuaType
---@param name string  类名
---@param ... LuaType interface
---@return T
function interface(name, ...) return CreateType(false, name, nil, ...) end

---@generic T:LuaType
---@param name string  类名
---@param super LuaType|nil 父类
---@param ... LuaType interface
---@return T
function class(name, super, ...) return CreateType(true, name, super, ...) end

---@param name string
---@return LuaType|nil
function Tools.GetType(name) return types[name] end

---@param _type LuaType
---@return string|nil
function Tools.GetTypeName(_type)
    local tableType, _ = Tools.GetTableType(_type)
    if tableType == TableType.Type or tableType == TableType.interface then return _type.__clsName end
    error("this is not class type or interface,but " .. tableType)
    return nil
end

---@param table table
---@return TableType,LuaType|nil
function Tools.GetTableType(table)
    local meta = getmetatable(table)
    if meta ~= nil then
        local __clsName = rawget(table, "__clsName")
        if __clsName and type(__clsName) == LuaDataType.String then
            if meta ~= interface_meta then
                return TableType.Type, table
            else
                return TableType.interface, table
            end
        end
        local _type = meta.__index
        if type(_type) == LuaDataType.Table then
            __clsName = rawget(_type, "__clsName")
            if __clsName and type(__clsName) == LuaDataType.String then return TableType.Instance, _type end
        end
    end
    return TableType.None, nil
end

---@param instance table
---@return LuaType|nil,TableType
function Tools.GetClassType(instance)
    local tableType, _type = Tools.GetTableType(instance)
    if tableType == TableType.Instance then return _type, tableType end
    error("this is not class instance,but " .. tableType)
    return nil, tableType
end

---@param instance table
---@param _type LuaType
---@return boolean
function Tools.IsTypeOfClass(instance, _type)
    local type = Tools.GetClassType(instance)
    if type then
        return Tools.IsAssignableFrom(type, _type)
    end
    return false
end

---@param type table
---@return LuaType|nil
function Tools.GetBaseType(type)
    local tableType, _type = Tools.GetTableType(type)
    if tableType == TableType.Type and _type ~= nil then return getmetatable(_type).__index end
    error("this is not class type,but " .. tableType)
end

---@param type LuaType
---@return table<LuaType>|nil
function Tools.GetInterfaces(type)
    local tableType, _type = Tools.GetTableType(type)
    if (tableType == TableType.Type and _type ~= nil) or tableType == TableType.interface then return type.__interfaces end
    error("this is not class type or interface ,but " .. tableType)
end

local function IsExtendsInterface(_type, parent)
    local interfaces = Tools.GetInterfaces(_type)
    if not interfaces then return false end
    for index, interface in ipairs(interfaces) do if interface == parent then return true end end
    return false
end
local function IsSubOfType(_type, parent)
    while true do
        ---@diagnostic disable-next-line: cast-local-type
        _type = Tools.GetBaseType(_type)
        if _type == parent then
            return true
        elseif _type == nil then
            return false
        end
    end
end
local function typeCheck(_type, parent)
    if _type == nil or parent == nil then
        error('param is nil')
        return false
    end
    local childTableType = Tools.GetTableType(_type)
    if childTableType ~= TableType.Type and childTableType ~= TableType.interface then
        error('type is not class type or interface,but ' .. childTableType)
        return false
    end
    local parentTableType = Tools.GetTableType(parent)
    if parentTableType ~= TableType.Type and parentTableType ~= TableType.interface then
        error('parent is not class type or interface,but ' .. parentTableType)
        return false
    end
    return true, parentTableType
end

---@param _type LuaType
---@param parent LuaType
---@return boolean
function Tools.IsSubClassOf(_type, parent)
    local success, parentTableType = typeCheck(_type, parent)
    if not success then return false end
    if _type == parent then return false end
    if parentTableType == TableType.interface then return IsExtendsInterface(_type, parent) end
    return IsSubOfType(_type, parent)
end

---@param _type LuaType
---@param parent LuaType
---@return boolean
function Tools.IsAssignableFrom(_type, parent)
    local success, parentTableType = typeCheck(_type, parent)
    if not success then return false end
    if _type == parent then return true end
    if parentTableType == TableType.interface then return IsExtendsInterface(_type, parent) end
    return IsSubOfType(_type, parent)
end
