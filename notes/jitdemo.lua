-- 定义一个函数，用于计算两个数的最大公约数
local function gcd(a, b)
  while b ~= 0 do -- 循环直到 b 为 0
    a, b = b, a % b -- 交换 a 和 b，并用 a 对 b 取余
  end
  return a -- 返回 a
end

-- 定义一个函数，用于计算两个数的最小公倍数
local function lcm(a, b)
  return a * b / gcd(a, b) -- 返回 a 和 b 的乘积除以它们的最大公约数
end

-- 调用 lcm 函数，传入两个较大的数作为参数
local x = lcm(123456789, 987654321)

-- 打印结果
print(x)