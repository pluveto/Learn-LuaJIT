# Day 2

指令为 32 位数据。

*src/lj_obj.h* 151:

```c
typedef uint32_t BCIns;  /* Bytecode instruction. */
```

包括 ABC  和 AD 两种格式。

*src/lj_bc.h* 12:

```c
/* Bytecode instruction format, 32 bit wide, fields of 8 or 16 bit:
**
** +----+----+----+----+
** | B  | C  | A  | OP | Format ABC
** +----+----+----+----+
** |    D    | A  | OP | Format AD
** +--------------------
** MSB               LSB
**
** In-memory instructions are always stored in host byte order.
*/
```

- ABC 格式，低 8 位为 OP，之后依次是操作数 A、B、C，各占 8 位。
- AD 格式，低 8 位为 OP，之后是操作数 A，占 8 位，D 占 16 位。

opr 的范围：

*src/lj_bc.h* 25:

```c
#define BCMAX_A		0xff
#define BCMAX_B		0xff
#define BCMAX_C		0xff
#define BCMAX_D		0xffff
```

字节码结构

*src/lj_bc.h*

这段代码是 Lua 字节码指令的定义，它定义了 Lua 虚拟机的指令集合，每一个指令都有一个唯一的操作码（opcode）和对应的操作数（operand）。

其中，每一个指令都以宏的形式定义，宏的名称为 `BCDEF`，它以 `_` 为参数，用于定义每个指令的具体操作和操作数。在宏中，每个指令都有如下的格式：

`(name, filler, Amode, Bmode, Cmode or Dmode, metamethod)`

- `name`：指令名称，是一个字符串。
- `filler`：指令是否需要填充，取值为 `dst`、`var`、`rbase` 或者 `base`，分别表示目标操作数、变量、基本寄存器或者基本寄存器组成的数组。
- `Amode`：操作数 A 的类型，取值为 `var`、`dst`、`base`、`rbase`、`lit`、`num`、`str`、`cdata`、`pri`、`func`、`uv` 或者 `jump`，分别表示变量、目标操作数、基本寄存器、基本寄存器组成的数组、常量、数字常量、字符串常量、C 数据常量、基本类型常量、函数常量、Upvalue、跳转地址。
- `Bmode`：操作数 B 的类型，和 Amode 类似。
- `Cmode or Dmode`：操作数 C 或者 D 的类型，和 Amode 类似。
- `metamethod`：如果这个指令对应了一个元方法，就是元方法的名称，否则为空。

？元方法实现对指令的一种简单分类。例如 ISEQV，ISNEV，ISEQS，ISNES，ISEQN，ISNEN，ISEQP，ISNEP 都属于元方法 eq，ISLT，ISGE，ISLE，ISGT 都属于元方法 lt。

在宏中，每个指令都以 `_(name, filler, Amode, Bmode, Cmode or Dmode, metamethod)` 的格式进行定义，多个指令之间以换行符进行分隔。其中，name 为宏的第一个参数，其余的参数依次对应 `name`、`filler`、`Amode`、`Bmode`、`Cmode or Dmode` 和 `metamethod`。

例如，`_(ISLT, var, ___, var, lt)` 表示定义了一个名为 `ISLT` 的指令，需要填充目标操作数，第一个操作数为变量，第二个操作数为空（占位符 `___`），第三个操作数为变量，它对应的元方法为 `lt`（小于比较）。这个指令的作用是比较两个变量的大小，如果第一个变量小于第二个变量，则将结果存储在目标操作数中，否则不做任何操作。

*src/lj_bc.h* 199:

```c
/* Bytecode opcode numbers. */
typedef enum {
#define BCENUM(name, ma, mb, mc, mt)	BC_##name,
BCDEF(BCENUM)
#undef BCENUM
  BC__MAX
} BCOp;
```

这里定义了一个枚举类型 `BCOp`，它包含了所有的指令，每个指令都有一个唯一的操作码（opcode）。

> BC_##name 的意思是将 name 替换为指令的名称。例如：`_(FUNCCW,	rbase,	___,	___,	___)` 将会被替换为 `BC_FUNCCW`。

展开后可以得到包含所有指令的 enum：

```c
typedef enum {

BC_ISLT, BC_ISGE, BC_ISLE, BC_ISGT, BC_ISEQV, BC_ISNEV, BC_ISEQS, BC_ISNES, BC_ISEQN, BC_ISNEN, BC_ISEQP, BC_ISNEP, BC_ISTC, BC_ISFC, BC_IST, BC_ISF, BC_ISTYPE, BC_ISNUM, BC_MOV, BC_NOT, BC_UNM, BC_LEN, BC_ADDVN, BC_SUBVN, BC_MULVN, BC_DIVVN, BC_MODVN, BC_ADDNV, BC_SUBNV, BC_MULNV, BC_DIVNV, BC_MODNV, BC_ADDVV, BC_SUBVV, BC_MULVV, BC_DIVVV, BC_MODVV, BC_POW, BC_CAT, BC_KSTR, BC_KCDATA, BC_KSHORT, BC_KNUM, BC_KPRI, BC_KNIL, BC_UGET, BC_USETV, BC_USETS, BC_USETN, BC_USETP, BC_UCLO, BC_FNEW, BC_TNEW, BC_TDUP, BC_GGET, BC_GSET, BC_TGETV, BC_TGETS, BC_TGETB, BC_TGETR, BC_TSETV, BC_TSETS, BC_TSETB, BC_TSETM, BC_TSETR, BC_CALLM, BC_CALL, BC_CALLMT, BC_CALLT, BC_ITERC, BC_ITERN, BC_VARG, BC_ISNEXT, BC_RETM, BC_RET, BC_RET0, BC_RET1, BC_FORI, BC_JFORI, BC_FORL, BC_IFORL, BC_JFORL, BC_ITERL, BC_IITERL, BC_JITERL, BC_LOOP, BC_ILOOP, BC_JLOOP, BC_JMP, BC_FUNCF, BC_IFUNCF, BC_JFUNCF, BC_FUNCV, BC_IFUNCV, BC_JFUNCV, BC_FUNCC, BC_FUNCCW,

  BC__MAX
} BCOp;
```

- 指令
  - ISLT: 如果第一个操作数小于第二个操作数，则将条件跳转指令压入堆栈。
    例子：if a < b then ... end

  - ISGE: 如果第一个操作数大于等于第二个操作数，则将条件跳转指令压入堆栈。
    例子：if a >= b then ... end

  - ISLE: 如果第一个操作数小于等于第二个操作数，则将条件跳转指令压入堆栈。
    例子：if a <= b then ... end

  - ISGT: 如果第一个操作数大于第二个操作数，则将条件跳转指令压入堆栈。
    例子：if a > b then ... end

  - ISEQV: 如果两个操作数相等且类型相同，则将条件跳转指令压入堆栈。
    例子：if a == b then ... end

  - ISNEV: 如果两个操作数不相等或类型不同，则将条件跳转指令压入堆栈。
    例子：if a ~= b then ... end

  - ISEQS: 如果两个操作数相等且都是字符串或数字，则将条件跳转指令压入堆栈。
    例子：if a == "hello" then ... end

  - ISNES: 如果两个操作数不相等或其中一个不是字符串或数字，则将条件跳转指令压入堆栈。
    例子：if a ~= "hello" then ... end

  - ISEQN: 如果两个操作数都是数字且相等，则将条件跳转指令压入堆栈。
    例子：if a == 10 then ... end

  - ISNEN: 如果两个操作数不相等或其中至少一个不是数字，则将条件跳转指令压入堆栈。
    例子：if a ~= 10 then ... end

  - ISEQP: 如果两个操作数都是同一个 Lua 对象，则将条件跳转指令压入堆栈。
    例子：if a is b then ... end

  - ISNEP: 如果两个操作数不是同一个 Lua 对象，则将条件跳转指令压入堆栈。
    例子：if a is not b then ... end

  - ISTC: 如果堆栈顶部的值是 true，则跳转。
    例子：if a then ... end

  - ISFC: 如果堆栈顶部的值是 false，则跳转。
    例子：if not a then ... end

  - IST: 如果堆栈顶部的值是 true，则将条件跳转指令压入堆栈。
    例子：if a then ... end

  - ISF: 如果堆栈顶部的值是 false，则将条件跳转指令压入堆栈。
    例子：if not a then ... end

  - ISTYPE: 如果堆栈顶部的值是指定类型，则将条件跳转指令压入堆栈。
    例子：if type(a) == "string" then ... end

  - ISNUM: 如果堆栈顶部的值是数字，则将条件跳转指令压入堆栈。
    例子：if type(a) == "number" then ... end

  - MOV: 将一个值从一个位置复制到另一个位置。
    例子：a = b

  - NOT: 将堆栈顶部的值进行逻辑非运算。
    例子：not a

  - UNM: 将堆栈顶部的值取相反数。
    例子：-a

  - LEN: 返回堆栈顶部的值的长度或大小。
    例子：#a

  - ADDVN: 将堆栈上的一个数字与常量中的一个数字相加。
    例子：a = a + 10

  - SUBVN: 将堆栈上的一个数字减去常量中的一个数字。
    例子：a = a - 10

  - MULVN: 将堆栈上的一个数字乘以常量中的一个数字。
    例子：a = a * 10

  - DIVVN: 将堆栈上的一个数字除以常量中的一个数字。
    例子：a = a / 10

  - MODVN: 将堆栈上的一个数字对常量中的一个数字取模。
    例子：a = a % 10

  - ADDNV: 将常量中的一个数字与堆栈上的一个数字相加。
    例子：a = 10 + a

  - SUBNV: 将常量中的一个数字减去堆栈上的一个数字。
    例子：a = 10 - a

  - MULNV: 将常量中的一个数字乘以堆栈上的一个数字。
    例子：a = 10 * a

  - DIVNV: 将常量中的一个数字除以堆栈上的一个数字。
    例子：a = 10 / a

  - MODNV: 将常量中的一个数字对堆栈上的一个数字取模。
    例子：a = 10 % a

  - ADDVV: 将堆栈上的两个数字相加。
    例子：a = a + b

  - SUBVV: 将堆栈上的两个数字相减。
    例子：a = a - b

  - MULVV: 将堆栈上的两个数字相乘。
    例子：a = a * b

  - DIVVV: 将堆栈上的两个数字相除。
    例子：a = a / b

  - MODVV: 将堆栈上的两个数字取模。
    例子：a = a % b

  - POW: 将堆栈上的两个数字进行指数运算。
    例子：a = a ^ b

  - CAT: 将堆栈上的多个字符串进行连接。
    例子：a = "Hello " .. "world"

  - KSTR: 将一个字符串常量压入堆栈。
    例子：a = "hello"

  - KCDATA: 将一个 C 数据常量压入堆栈。
    例子：a = ffi.new("int[1]", 10)

  - KSHORT: 将一个短整型常量压入堆栈。
    例子：a = 10

  - KNUM: 将一个数字常量压入堆栈。
    例子：a = 3.14

  - KPRI: 将一个 Lua 值类型的常量压入堆栈。
    例子：a = nil

  - KNIL: 将一个 nil 值压入堆栈。
    例子：a = nil

  - UGET: 将一个 upvalue 的值压入堆栈。
    例子：a = upvalue

  - USETV: 将堆栈上的一个值存储到一个 upvalue 中。
    例子：upvalue = a

  - USETS: 将堆栈上的一个字符串存储到一个 upvalue 中。
    例子：upvalue = "hello"

  - USETN: 将堆栈上的一个数字存储到一个 upvalue 中。
    例子：upvalue = 10

  - USETP: 将堆栈上的一个 Lua 值类型存储到一个 upvalue 中。
    例子：upvalue = nil

  - UCLO: 创建一个新的闭包函数，并将其压入堆栈。
    例子：function foo() return 42 end

  - FNEW: 创建一个新的 C 函数对象，并将其压入堆栈。
    例子：function my_c_function(L) print("Hello from C!") end

  - TNEW: 创建一个新的 Lua 表，并将其压入堆栈。
    例子：my_table = {}

  - TDUP: 复制一个 Lua 表，并将其压入堆栈。
    例子：my_table_copy = my_table

  - GGET: 获取一个全局变量的值，并将其压入堆栈。
    例子：a = global_variable

  - GSET: 设置一个全局变量的值。
    例子：global_variable = a

  - TGETV: 从表中获取一个值，并将其压入堆栈。
    例子：a = my_table[key]

  - TGETS: 从表中获取一个字符串键对应的值，并将其压入堆栈。
    例子：a = my_table["key"]

  - TGETB: 从表中获取一个布尔键对应的值，并将其压入堆栈。
    例子：a = my_table[true]

  - TGETR: 从表中获取一个浮点数键对应的值，并将其压入堆栈。
    例子：a = my_table[3.14]

  - TSETV: 将堆栈上的一个值存储到表中。
    例子：my_table[key] = a

  - TSETS: 将堆栈上的一个字符串存储到表中。
    例子：my_table["key"] = "value"

  - TSETB: 将堆栈上的一个布尔值存储到表中。
    例子：my_table[true] = false

  - TSETM: 将堆栈上的多个值存储到表中。
    例子：my_table[key1][key2] = value

  - TSETR: 将堆栈上的一个浮点数存储到表中。
    例子：my_table[3.14] = value

  - CALLM: 调用一个方法，并将其结果压入堆栈。
    例子：obj:method(arg1, arg2)

  - CALL: 调用一个函数，并将其结果压入堆栈。
    例子：my_function(arg1, arg2)

  - CALLMT: 调用一个方法，并将其结果作为多个返回值压入堆栈。
    例子：ret1, ret2 = obj:method(arg1, arg2)

  - CALLT: 调用一个函数，并将其结果作为多个返回值压入堆栈。
    例子：ret1, ret2 = my_function(arg1, arg2)

  - ITERC: 迭代一个 C 函数，并将其结果压入堆栈。
    例子：for k, v in ipairs(my_table) do print(k, v) end

  - ITERN: 迭代一个 Lua 函数，并将其结果压入堆栈。
    例子：for k, v in pairs(my_table) do print(k, v) end

  - VARG: 将一个连续的参数列表推入堆栈。
    例子：my_function(...)

  - ISNEXT: 判断下一条指令是否是 FOR 循环中的 OP_JMP。
    例子：判断 for 循环是否结束

  - RETM: 从一个函数中返回多个值，并将结果放回调用栈中。
    例子：return a, b, c

  - RET: 从一个函数中返回一个值，并将其放回调用栈中。
    例子：return a

  - RET0: 从一个函数中返回 0 个值，并将其放回调用栈中。
    例子：return

  - RET1: 从一个函数中返回 1 个值，并将其放回调用栈中。
    例子：return a

  - FORI: 执行一个 FOR 循环的迭代操作。
    例子：for i = 1, 10 do ... end

  - JFORI: 跳转到 FOR 循环的迭代操作。
    例子：跳出 for 循环

  - FORL: 执行一个 FOR 循环的迭代操作。
    例子：for k, v in pairs(my_table) do ... end

  - IFORL: 初始化一个 FOR 循环的迭代器。
    例子：for k, v in pairs(my_table) do ... end

  - JFORL: 跳转到 FOR 循环的迭代操作。
    例子：跳出 for 循环

  - ITERL: 迭代一个 Lua 函数。
    例子：for k, v in pairs(my_table) do ... end

  - IITERL: 初始化一个迭代器。
    例子：for k, v in pairs(my_table) do ... end

  - JITERL: 跳转到迭代器的下一个元素。
    例子：for k, v in pairs(my_table) do ... end

  - LOOP: 循环指令。
    例子：while true do ... end

  - ILOOP: 初始化一个循环。
    例子：while true do ... end

  - JLOOP: 跳转到循环开始处。
    例子：重新开始一个循环

  - JMP: 无条件跳转。
    例子：跳转到指定位置

  - FUNCF: 创建一个闭包函数。
    例子：local my_function = function(...) ... end

  - IFUNCF: 初始化一个闭包函数。
    例子：local my_function = function(...) ... end

  - JFUNCF: 跳转到闭包函数。
    例子：调用一个闭包函数

  - FUNCV: 创建一个闭包函数。
    例子：local my_function = function(...) ... end

  - IFUNCV: 初始化一个闭包函数。
    例子：local my_function = function(...) ... end

  - JFUNCV: 跳转到闭包函数。
    例子：调用一个闭包函数

  - FUNCC: 创建一个 C 函数。
    例子：local my_function = function(...) ... end

  - FUNCCW: 创建一个 C 函数。
    例子：local my_function = function(...) ... end

操作数类型

*src/lj_bc.h* 238:

```c
/* Bytecode operand modes. ORDER BCMode */
typedef enum {
  BCMnone, BCMdst, BCMbase, BCMvar, BCMrbase, BCMuv,  /* Mode A must be <= 7 */
  BCMlit, BCMlits, BCMpri, BCMnum, BCMstr, BCMtab, BCMfunc, BCMjump, BCMcdata,
  BCM_max
} BCMode;
#define BCM___		BCMnone
```

该枚举定义了字节码操作数的各种模式，用于表示字节码中操作数的类型。具体来说，它包括了以下模式：

- BCMnone: 没有操作数。
- BCMdst: 目标操作数，用于存储结果。
- BCMbase: 基本操作数，用于存储地址。
- BCMvar: 变量操作数，用于存储变量名。
- BCMrbase: 寄存器基址操作数，用于存储基址。
- BCMuv: Upvalue 操作数，用于存储 upvalue。
- BCMlit: 字面量操作数，用于存储常量。
- BCMlits: 字符串常量操作数，用于存储字符串常量。
- BCMpri: 原始类型操作数，用于存储原始类型的值。
- BCMnum: 数字操作数，用于存储数字。
- BCMstr: 字符串操作数，用于存储字符串。
- BCMtab: 表操作数，用于存储表。
- BCMfunc: 函数操作数，用于存储函数。
- BCMjump: 跳转操作数，用于存储跳转目标。
- BCMcdata: 常量数据操作数，用于存储常量数据。

其中，BCMnone 是默认值，BCM___ 是用来在枚举定义中补齐位数的占位符。

*src/lj_bc.h* 246:

```c
#define bcmode_a(op)	((BCMode)(lj_bc_mode[op] & 7))
#define bcmode_b(op)	((BCMode)((lj_bc_mode[op]>>3) & 15))
#define bcmode_c(op)	((BCMode)((lj_bc_mode[op]>>7) & 15))
#define bcmode_d(op)	bcmode_c(op)
#define bcmode_hasd(op)	((lj_bc_mode[op] & (15<<3)) == (BCMnone<<3))
#define bcmode_mm(op)	((MMS)(lj_bc_mode[op]>>11))

#define BCMODE(name, ma, mb, mc, mm) \
  (BCM##ma|(BCM##mb<<3)|(BCM##mc<<7)|(MM_##mm<<11)),
#define BCMODE_FF	0

static LJ_AINLINE int bc_isret(BCOp op)
{
  return (op == BC_RETM || op == BC_RET || op == BC_RET0 || op == BC_RET1);
}

LJ_DATA const uint16_t lj_bc_mode[];
LJ_DATA const uint16_t lj_bc_ofs[];
```

这段代码定义了一些宏和全局变量，用于处理字节码指令的操作数模式。

- `bcmode_a(op)` 宏用于获取操作码为 `op` 的指令的第一个操作数的模式（取操作码的低 3 位），返回一个 `BCMode` 类型的值。
- `bcmode_b(op)` 宏用于获取操作码为 `op` 的指令的第二个操作数的模式（取操作码的第 4 位到第 6 位），返回一个 `BCMode` 类型的值。
- `bcmode_c(op)` 宏用于获取操作码为 `op` 的指令的第三个操作数的模式（取操作码的第 8 位到第 10 位），返回一个 `BCMode` 类型的值。
- `bcmode_d(op)` 宏和 `bcmode_c(op)` 作用相同，用于获取指令的第四个操作数的模式，因为有些指令会有四个操作数。在实现上，它直接调用了 `bcmode_c(op)`。
- `bcmode_hasd(op)` 宏用于判断操作码为 `op` 的指令是否有第四个操作数。
- `bcmode_mm(op)` 宏用于获取操作码为 `op` 的指令的元方法索引（取操作码的高 5 位），返回一个 `MMS` 类型的值。

此外，代码还定义了一个 `BCMODE` 宏和一个 `BCMODE_FF` 常量。`BCMODE` 宏用于将操作数模式组合成一个 16 位的值，它的参数是一个操作数模式名称和三个操作数的模式，返回一个组合后的 16 位值。`BCMODE_FF` 常量的值为 0，它在定义操作数模式时用于填充不需要的操作数模式。

最后，代码还定义了两个全局变量 `lj_bc_mode` 和 `lj_bc_ofs`，它们是 uint16_t 类型的数组。其中 `lj_bc_mode` 数组存储了每个字节码指令的操作数模式组合成的 16 位值，而 `lj_bc_ofs` 数组存储了每个字节码指令的操作数在指令中的偏移量。

这里的 MM 就是元方法的缩写。

*src/lj_obj.h* 541:

```c
/* Metamethods. ORDER MM */
#ifdef LJ_HASFFI
#define MMDEF_FFI(_) _(new)
#else
#define MMDEF_FFI(_)
#endif

#if LJ_52 || LJ_HASFFI
#define MMDEF_PAIRS(_) _(pairs) _(ipairs)
#else
#define MMDEF_PAIRS(_)
#define MM_pairs	255
#define MM_ipairs	255
#endif

#define MMDEF(_) \
  _(index) _(newindex) _(gc) _(mode) _(eq) _(len) \
  /* Only the above (fast) metamethods are negative cached (max. 8). */ \
  _(lt) _(le) _(concat) _(call) \
  /* The following must be in ORDER ARITH. */ \
  _(add) _(sub) _(mul) _(div) _(mod) _(pow) _(unm) \
  /* The following are used in the standard libraries. */ \
  _(metatable) _(tostring) MMDEF_FFI(_) MMDEF_PAIRS(_)

typedef enum {
#define MMENUM(name)	MM_##name,
MMDEF(MMENUM)
#undef MMENUM
  MM__MAX,
  MM____ = MM__MAX,
  MM_FAST = MM_len
} MMS;
```

展开之后：

*src/lj_obj_extend.h* 2204:

```cpp
typedef enum {

MM_index, MM_newindex, MM_gc, MM_mode, MM_eq, MM_len, MM_lt, MM_le, MM_concat, MM_call, MM_add, MM_sub, MM_mul, MM_div, MM_mod, MM_pow, MM_unm, MM_metatable, MM_tostring, MM_new, MM_pairs, MM_ipairs,

  MM__MAX,
  MM____ = MM__MAX,
  MM_FAST = MM_len
} MMS;
```

这段代码定义了 Lua 中的元方法（metamethods），元方法是一种特殊的函数，可以控制 Lua 对象的行为。这个枚举类型列出了所有 Lua 中支持的元方法，按照一定的顺序排列。其中 `MMDEF` 是一个宏，展开成一个以 `_` 为参数的函数序列，这些函数名对应了各种元方法的名字。然后通过 `MMENUM` 宏展开成 `MM_` 前缀加上元方法名字的常量。`MM__MAX` 是元方法常量的总数，`MM____` 和 `MM_FAST` 是一些元方法的边界标记。`MMS` 是一个枚举类型，其中 `MM_FAST` 是这个枚举中最后一个元素，因此可以用于快速遍历元方法。

- `index`: 当 Lua table 被使用索引操作符 `[]` 访问时调用，用于返回指定键的值。
- `newindex`: 当 Lua table 被使用赋值操作符 `[]=` 赋值时调用，用于设置指定键的值。
- `gc`: 当 Lua 对象被垃圾回收器回收时调用，用于清理对象占用的资源。
- `mode`: 用于控制虚拟机的运行模式。
- `eq`: 用于检查两个对象是否相等。
- `len`: 当对象被使用 `#` 操作符计算长度时调用，用于返回对象的长度。
- `lt`: 用于比较两个对象是否小于。
- `le`: 用于比较两个对象是否小于等于。
- `concat`: 当对象被使用 `..` 操作符进行字符串拼接时调用，用于返回拼接后的结果。
- `call`: 当对象被作为函数调用时调用。
- `add`: 用于两个对象相加。
- `sub`: 用于两个对象相减。
- `mul`: 用于两个对象相乘。
- `div`: 用于两个对象相除。
- `mod`: 用于两个对象求模。
- `pow`: 用于两个对象求幂。
- `unm`: 用于求对象的负数。
- `metatable`: 返回对象的元表。
- `tostring`: 将对象转换为字符串。
- `new`: 创建新的对象，通常与元表的 `__call` 方法一起使用。
- `pairs`: 用于迭代 Lua table 中的键值对。
- `ipairs`: 用于迭代 Lua table 中的数组部分。

通过 `./luajit -bl ../tests/hello.lua` 可以查看把源码编译为文本格式的字节码表示。

例子：

```lua
-- BYTECODE -- hello.lua:0-1
0001    GGET     0   0      ; "print"
0002    KSTR     2   1      ; "hello, world!"
0003    CALL     0   1   2
0004    RET0     0   1
```

