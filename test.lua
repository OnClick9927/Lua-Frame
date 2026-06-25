require("index")
---@type ValueContainer
local values = ValueContainer()

---@class IEat:LuaType
local IEat = interface("IEat")
function IEat:Eat() end

---@class IShout:LuaType
local IShout = interface("IShout")
function IShout:Shout() end

---@class IHuman:IShout,IEat
local IHuman = interface("IHuman", IShout, IEat)
---@class IDog:IEat
local IDog = interface("IDog", IEat)

---@class A:IHuman
local A = class("A", nil, IHuman)
---@private
function A:ctor(name)
    self.name = name
    print(name)
end

function A:Eat(test)
    print('man eat')
end

function A:Shout(test)
    print('man shout')
end

---@class B:A
local B = class("B", A)
---@private
function B:ctor(name, age)
    self.age = age
end

function B:Shout()
    A.Shout(self)
    print('B shout Again')
end

---@class Dog:IDog
local Dog = class("Dog", nil, IDog)

function Dog:ctor(human, name)
    ---@type IHuman
    self.human = human
    self.name = name
end

function Dog:Eat()
    self.human:Eat()
    print('dog eat')
    self.human:Shout()
end

local human = B("wang", 15)
values:SetValueAs(human, IHuman)
values:SetValueAsFunc(IDog, Dog, IHuman)

---@type IDog
local dog = values:GetValue(IDog, "chun")

if dog then
    dog:Eat()
end











try {
    function()
        print("1111")
        error("big err")
    end,
    catch = function(e)
        print(e .. "  222")
    end,
    finally = function()
        print(3333)
    end

}
print(0, os.time())

local finish
async(
    function(sec)
        await(LuaTask.Delay(sec))
        print(1, os.time())
        finish = true
    end
)(2)
print(2, os.time())


while not finish do
    os.execute("timeout /t " .. 1 .. " /nobreak")

    Tools.UpdateTimers()
end
