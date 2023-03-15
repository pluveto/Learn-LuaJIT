-- 使用 ffi 库来调用 C 函数和访问 C 数据
local ffi = require("ffi")
ffi.cdef[[
int printf(const char *fmt, ...);
]]
ffi.C.printf("Hello, world!\n")

-- 使用 bit 库来进行位运算
local bit = require("bit")
local x = bit.bor(0x1234, 0x5678) -- 按位或运算
local y = bit.bxor(x, 0xffff) -- 按位异或运算
print(x, y)

-- 使用 table 库来创建和操作表
local t = {} -- 创建一个空表
for i = 1, 10 do
  t[i] = i * i -- 插入元素
end
table.sort(t, function(a, b) return a > b end) -- 排序表
for k, v in pairs(t) do -- 遍历表
  print(k, v)
end

-- 使用 math 库来进行数学运算
local a = math.sin(math.pi / 6) -- 正弦函数
local b = math.cos(math.pi / 3) -- 余弦函数
local c = math.sqrt(a * a + b * b) -- 平方根函数
print(a, b, c)

-- 使用 string 库来处理字符串
local s = "Hello, LuaJIT!" -- 创建一个字符串
local n = string.len(s) -- 获取字符串长度
local u = string.upper(s) -- 转换为大写
local r = string.reverse(s) -- 反转字符串
print(n, u, r)

-- 使用 coroutine 库来创建和管理协程
local co = coroutine.create(function() -- 创建一个协程
  for i = 1, 5 do
    print("co", i)
    coroutine.yield() -- 暂停协程
  end
end)
for i = 1, 5 do
  print("main", i)
  coroutine.resume(co) -- 恢复协程
end

-- 使用 jit 库来控制 JIT 编译器的行为
jit.on() -- 开启 JIT 编译器
jit.off() -- 关闭 JIT 编译器
jit.flush() -- 清空跟踪缓存

-- 使用 Lua 的语法特性来编写函数和控制流程
function fib(n) -- 定义一个斐波那契数列的函数
  if n < 2 then return n end -- 边界条件
  return fib(n - 1) + fib(n - 2) -- 递归调用
end

for i = 0, 10 do -- 循环语句
  print(fib(i))
end

if x > y then -- 条件语句
  print("x is greater than y")
elseif x < y then
  print("x is less than y")
else
  print("x is equal to y")
end
