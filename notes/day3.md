# Lua 的字节码指令详解

## 说明

本文主要参考为 LuaJIT 源码的 `src/vm_x64.dasc`，总结得出，如有错误，欢迎指正。

## 指令总结

- MULVN: mul var num，变量与数字相乘
  - OP: 运算类型为 mul，运算数分别是 var 和 num。
  - RA: 输出寄存器
  - RD: 输入寄存器
- 例子: `MULVN 1 0 0`，将 0 号寄存器中的值乘以 2，将结果存放在 1 号寄存器中。

- RET1: return 1，返回 1 个值
  - OP: 运算类型为 return，返回值数量为 1。
  - RA: 返回值所在寄存器
  - RD: 返回值数量+1
- 例子: `RET1 1 2`，返回 1 号寄存器中的值，返回值数量为 1 个。
- 例子: `RET 0 4`，返回 0 号寄存器中的值，返回值数量为 3 个。

- FNEW: function new，创建一个新的函数对象
  - OP: 运算类型为 function，创建一个新的函数对象。
  - RA: 输出寄存器，存放函数对象。
  - RD: 输入寄存器，存放函数的原型常量，例如 `func.lua:1`
- 例子: `FNEW 0 0`，创建一个新的函数对象，存放在 0 号寄存器中。
- 注意：FNEW 会将函数通过 `lj_func_newL_gc` 注册到 L （luaState）里。这时候还没有名字，通过后面的 GSET 指令绑定到名称。后面要用到的时候在通过 GGET 拿出来就行。

- GSET: global set，全局设置
  - OP: 运算类型为 set，将寄存器存储在全局变量中。
  - RA: 输入寄存器，存放函数对象。
  - RD: 输入寄存器，存放字符串常量的地址。
- 例子: `GSET 0 1`，将寄存器 1 的字符串常量与 0 所表示的对象关联起来。可以理解为哈希表的 set
- GSET 通过 TSET 实现。

- GGET: global get，全局获取
  - OP: 运算类型为 get，从全局变量中获取值。
  - RA: 输出寄存器，存放全局变量的值。
  - RD: 输入寄存器，存放字符串常量的地址。
- 例子: `GGET 0 1`，从全局变量中获取值，key 为 1 所指向的字符串，将其存放在 0 号寄存器中。可以理解为哈希表的 get

- KSHORT: key short，把短整型常量放到寄存器中
  - OP: 运算类型为 key，将短整型常量存放在寄存器中。
  - RA: 输出寄存器，存放短整型常量。
  - RD: 输入字面值，存放短整型常量。即有符号的 16 位整数。
- 例子: `KSHORT 2 11`，将数字 11 存放在 2 号寄存器中。

- CALL: call，调用函数
  - OP: 运算类型为 call，调用函数。
  - RA: 输入寄存器，存放函数的基本地址。
  - RB：输入寄存器，存放函数的返回值数量+1。
  - RC：输入寄存器，存放函数的参数数量+1。或者存放一个额外参数。
- 例子: `CALL 0 1 2`，调用 0 号寄存器中的函数，返回值数量为 0 个，参数数量为 1 个。

- RET0: return 0，返回 0 个值
  - OP: 运算类型为 return，返回值数量为 0。
  - RA: 返回值所在寄存器
  - RD: 返回值数量+1
- 例子：`RET0 0 1`，返回值数量为 0 个。

- TNEW: table new，创建一个新的 table 对象
  - OP: 运算类型为 table，创建一个新的 table 对象。
  - RA: 输出寄存器，存放 table 对象地址。
  - RD: 输入寄存器，存放 hbits|asize
    - hbits: 低 12 位，hash slot 的数量的2对数。例如 8，表示 2^8=256 个 hash slot。
    - asize: 高 24 位，数组的大小。

- TSETS: table set string，设置 table 的 key 为字符串
  - OP: 运算类型为 table set，设置 table 的 key 为字符串。
  - RA: 输入寄存器，存放 value 的地址。
  - RB: 输入寄存器，存放 table 的地址。
  - RC: 输入寄存器，存放 key 的字符串常量地址。

- TSETV: table set var，设置 table 的 key 为变量
  - OP: 运算类型为 table set，设置 table 的 key 为变量。
  - RA: 输入寄存器，存放 value 的地址。
  - RB: 输入寄存器，存放 table 的地址。
  - RC: 输入寄存器，存放 key 的地址。

- JMP：jump，跳转
  - OP: 运算类型为 jump，跳转。
  - RD: 输入字面值，存放跳转的偏移量。
- 备注：通过修改 PC 实现跳转。

- ITERC: iterator call，调用迭代器
  - OP: 运算类型为 iterator，调用迭代器。
  - RA: 输入寄存器，存放迭代器的基本地址。
  - RB：输入寄存器，存放迭代器的返回值数量+1。
  - RC：输入寄存器，存放迭代器的参数数量+1 | 额外参数。
- 备注：可以看作一种特殊的 CALL 指令。

- ITERL: iterator loop，迭代器循环
  - 还在研究。

- CALLM: call with multiple return，调用函数，返回多个值
  - OP: 运算类型为 call，调用函数。
  - RA: 输入寄存器，存放函数的基本地址。
  - RB：输入寄存器，存放函数的返回值数量+1。
  - RC：输入寄存器，存放函数的额外参数

- MOV: move，移动
  - OP: 运算类型为 move。
  - RA: 输出地址
  - RD: 输入地址
