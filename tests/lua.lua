-- 定义一个函数，它将接受一个参数并返回该参数的两倍
function double(x)
    return x * 2
  end
  
  -- 将表（table）作为一个类使用，使用元表（metatables）来实现面向对象编程
  Person = {}
  Person.__index = Person
  
  function Person:new(name, age)
    local self = setmetatable({}, Person)
    self.name = name
    self.age = age
    return self
  end
  
  function Person:get_name()
    return self.name
  end
  
  function Person:get_age()
    return self.age
  end
  
  -- 使用闭包（closures）创建一个工厂函数，用于创建特定类型的对象
  function create_person(name, age)
    return Person:new(name, age)
  end
  
  -- 使用迭代器（iterators）实现遍历数组（arrays）和表（tables）
  array = {1, 2, 3, 4, 5}
  for i, v in ipairs(array) do
    print(i, v)
  end
  
  table = {a = 1, b = 2, c = 3}
  for k, v in pairs(table) do
    print(k, v)
  end
  
  -- 使用协同程序（coroutines）实现非阻塞式调用
  co = coroutine.create(function()
    print("Hello")
    coroutine.yield()
    print("World")
  end)
  
  coroutine.resume(co)
  coroutine.resume(co)
  
  -- 使用模式匹配（pattern matching）实现字符串操作
  str = "hello world"
  print(string.upper(str))
  print(string.gsub(str, "l", "L"))
  print(string.match(str, "w%a+"))
  
  -- 使用可变参数（variable arguments）实现函数的灵活性
  function sum(...)
    local total = 0
    for _, v in ipairs({...}) do
      total = total + v
    end
    return total
  end
  
  print(sum(1, 2, 3, 4, 5))
  
  -- 使用元表（metatables）实现自定义类型的操作
  MyType = {}
  MyType.__index = MyType
  
  function MyType:new(value)
    local self = setmetatable({}, MyType)
    self.value = value
    return self
  end
  
  function MyType:add(other)
    return MyType:new(self.value + other.value)
  end
  
  function MyType:__tostring()
    return tostring(self.value)
  end
  
  mt1 = MyType:new(10)
  mt2 = MyType:new(20)
  print(mt1:add(mt2))
