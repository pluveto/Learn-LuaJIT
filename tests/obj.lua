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

function create_person(name, age)
  return Person:new(name, age)
end