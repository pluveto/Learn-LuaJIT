LuaJIT 虚拟机支持八种基本的数据类型，分别是：

- nil：表示不存在或无效的值，只有一个值 nil。
- boolean：表示逻辑真假，有两个值 true 和 false。
- number：表示实数，可以是整数或浮点数。
- string：表示文本，是不可变的字节序列。
- table：表示关联数组，是可变的键值对集合。
- function：表示可执行的代码块，可以是 Lua 函数或 C 函数。
- userdata：表示任意的 C 数据，可以有元表和方法。
- thread：表示独立的执行线程，可以有自己的栈和局部变量。

LuaJIT 虚拟机使用一种叫做 **Tagged Value 表示法** 的来存储和操作这些数据类型。Tag Value 表示法是指每个 Lua 值由两部分组成：

- 类型标签（tag）：表示值的数据类型，占用一个字节。
- 值数据（data）：表示值的具体内容，占用七个字节。

类型标签和值数据共同构成一个 **TValue** 结构体，占用八个字节。TValue 结构体在 LuaJIT 的源码中定义如下：

```c
typedef struct TValue {
  uint64_t u64;
} TValue;
```

其中，u64 是一个 64 位无符号整数，用来存储类型标签和值数据。类型标签在 u64 的最高位字节（第 56~63 位），值数据在 u64 的其余位（第 0~55 位）。例如，一个 Lua 值 true 的 TValue 结构体如下：

```c
{ u64 = 0x 00 00 00 00 00 00 00 02 }
```

（注：使用大端序）

其中，0x02 是 boolean 类型的类型标签，0x00000000000000 是 true 值的值数据。

LuaJIT 虚拟机使用一系列的宏定义来操作 TValue 结构体中的类型标签和值数据。这些宏定义在 LuaJIT 的源码中的 lj_obj.h 文件中。例如：

- tvisbool(tv)：判断一个 TValue 是否是 boolean 类型。
- boolV(tv)：从一个 TValue 中获取 boolean 值。
- setboolV(tv, x)：设置一个 TValue 为 boolean 值 x。

这些宏定义使得 LuaJIT 虚拟机可以方便地对 TValue 结构体进行读写和转换。

LuaJIT 虚拟机为每种数据类型定义了不同的类型标签和值数据的格式。具体如下：

- nil 类型只有一个值 nil，其类型标签为 LJ_TNIL（0xFF），值数据为全零。例如：

```c
{ u64 = 0x00000000000000FF }
```

- boolean 类型有两个值 true 和 false，其类型标签为 LJ_TFALSE（0xFE）和 LJ_TTRUE（0xFD），值数据为全零。例如：

```c
{ u64 = 0x00000000000000FE } // false
{ u64 = 0x00000000000000FD } // true
```

- number 类型可以是整数或浮点数，其类型标签为 LJ_TISNUM（0x01），值数据为整数或浮点数的二进制表示。例如：

```c
{ u64 = 0x0000000100000041 } // 整数 1
{ u64 = 0x3FF0000000000041 } // 浮点数 1.0
```

注意，由于 LuaJIT 虚拟机使用小端字节序存储 TValue 结构体，所以值数据的低位字节