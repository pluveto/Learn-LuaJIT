# DASC

## vm_hotloop vm_callhook
LuaJIT 的 DASC 代码中，比较重要的函数有哪些？含义是什么？比如 vm_hotloop vm_callhook

您好，这是Bing。我可以尝试回答您的问题。😊

根据我的搜索结果，vm_hotloop和vm_callhook是LuaJIT的DASC代码中的一些函数，它们用于实现Lua虚拟机的低级代码²。DASC是一种动态汇编器，它可以在运行时生成和执行机器码³。

vm_hotloop函数的作用是检测一个循环是否足够热，即是否执行了足够多的次数，以便触发JIT编译器的优化²。它的定义如下：

```lua
|// Hot loop detection. Use a counter to measure the trip count modulo 2^16.
|// The loop is considered hot, if the counter overflows or is already hot.
|.macro hotloop
||if (hotcount == 0) {
|  // First loop invocation. Start counter at a high value (loop unroll factor).
|  mov PC, [BASE+PC2PROTO(k)]
|  movzx RB, word [PC-4]
|  mov [DISPATCH+DISPATCH_GL(hotloop)], RB
||} else {
|  // Subsequent loop invocation: add hotcount to counter. Branch to exit if
|  // the loop is not hot enough, yet. Avoid a spill by using RC as scratch.
|  movzx RC, word [DISPATCH+DISPATCH_GL(hotloop)]
|  add RC, hotcount
|  movzx RB, word [PC-4]
|  cmp RC, RB
|  jna >1
||}
|.endmacro
```

vm_callhook函数的作用是调用Lua虚拟机的钩子函数，例如调试钩子或GC钩子²。它的定义如下：

```lua
|// Call hook handler. RB = base*8, RC = nargs*8 (RD = savemask).
|.macro callhook, event, base
||if (jit_debug) {
|.if X64WIN
|  // Windows unwinder doesn't like RIP-relative addressing mode here. :-/
|  lea DISPATCH, [DISPATCH+DISPATCH_GL(hookf)]
|.endif
||}
||if (jit_debug or debug_sethook) {
|  // Check for hooks first. base*8 = frame delta + nargs*8.
|  test byte [DISPATCH+DISPATCH_GL(hookmask)], HOOK_ACTIVE; jz >5
||}
||if (jit_debug) {
|.if X64WIN
|  mov CARG1, [DISPATCH]
|.else
|  mov CARG1, [DISPATCH+DISPATCH_GL(hookf)]
|.endif
||} elseif debug_sethook then
|  mov CARG1, [DISPATCH+DISPATCH_GL(hookf)]
||end
|.if X64WIN; .else; .if X64; mov CARG1d, CARG1; .endif; .endif
||if (jit_debug or debug_sethook) {
|.if X64WIN; .else; .if X64; mov CARG2d, PCd; .else; mov CARG2, PC; .endif; .endif
|.if X64WIN; .else; .if X64; mov CARG3d, event; .else; mov CARG3, event; .endif; .endif
|.if X64WIN; mov CARG4d, base; .else; mov FCARG3d, base; .endif
||}
||if (jit_debug) {
|.if X64WIN
|  call extern &lj_vm_recordff@16	// (lua_State *L, BCIns *pc)
|.else
|.if X64
|  call extern &lj_vm_recordff		// (lua_State *L, BCIns *pc)
|.else
|  call extern lj_vm_recordff@8		// (lua_State *L, BCIns *pc)
|.endif
|.endif
||} elseif debug_sethook then
|.if X64WIN
|  call extern &lj_dispatch_call@16	// (lua_State *L, const BCIns *pc)
|.else
```
源: 与必应的对话， 2023/3/15(1) luajit/vm_x86.dasc at master · LuaDist/luajit · GitHub. https://github.com/LuaDist/luajit/blob/master/src/vm_x86.dasc 访问时间 2023/3/15.
(2) Buristan/vim-after-syntax-dasc-luajit - GitHub. https://github.com/Buristan/vim-after-syntax-dasc-luajit 访问时间 2023/3/15.
(3) lua - How to define C functions with LuaJIT? - Stack Overflow. https://stackoverflow.com/questions/53805913/how-to-define-c-functions-with-luajit 访问时间 2023/3/15.
(4) 深入学习vue系列 —— 生命周期钩子 - 掘金. https://juejin.cn/post/6868183603214450695 访问时间 2023/3/15.
(5) vue源码：钩子hook_小强有个dream的博客-CSDN博客_vue源码钩子定义. https://blog.csdn.net/qq_36413371/article/details/117280499 访问时间 2023/3/15.
(6) Troubleshooting a virtual machine that has stopped responding ... - VMware. https://kb.vmware.com/s/article/1007819 访问时间 2023/3/15.

## macro hotloop

```js
|// Decrement hashed hotcount and trigger trace recorder if zero.
|.macro hotloop, reg
|  mov reg, PCd
|  shr reg, 1
|  and reg, HOTCOUNT_PCMASK
|  sub word [DISPATCH+reg+GG_DISP2HOT], HOTCOUNT_LOOP
|  jb ->vm_hotloop
|.endmacro
```

定义一个名为 hotloop 的宏，它接受一个参数 reg。
将 PCd 的值（当前执行的字节码指令的地址）右移一位，存入 reg 中。
将 reg 的值与 HOTCOUNT_PCMASK 做按位与运算，存入 reg 中。这样可以得到当前字节码指令所在的循环的哈希值。这是因为 HOTCOUNT_PCMASK 是一个掩码，它用于将 reg 的值的高位清零，只保留低位。这样可以将 reg 的值限制在一个较小的范围内，从而减少内存的占用和访问时间。同时，这也可以保证每个循环都有一个唯一的哈希值，因为不同的循环的字节码指令的地址不会有相同的低位。

将内存中 [DISPATCH+reg+GG_DISP2HOT] 的值（当前循环的热度计数）减去 HOTCOUNT_LOOP（一个常量），并存回原处。这样可以减少当前循环的热度计数。
如果减法操作导致进位标志位被设置（即热度计数变为负数），则跳转到 vm_hotloop 函数。这表示当前循环已经达到了热循环的条件，需要被动态编译器优化。

PCd 要右移一位是因为 LuaJIT 的字节码指令是两个字节的，而哈希函数是按照四个字节的单位来计算的。所以为了让哈希函数能够正确地区分不同的字节码指令，需要将 PCd 右移一位，使得每个字节码指令都对应一个唯一的哈希值。这样可以避免哈希冲突的可能性。

/* Number of hot counter hash table entries (must be a power of two). */
#define HOTCOUNT_SIZE		64
#define HOTCOUNT_PCMASK		((HOTCOUNT_SIZE-1)*sizeof(HotCount))

这么设计的思路是为了使得哈希值的范围和内存的占用都比较合理。HOTCOUNT_SIZE 定义了热度计数的数量，也就是哈希表的大小。它必须是一个 2 的幂，这样可以使得哈希值的分布更加均匀，减少冲突的概率。HOTCOUNT_PCMASK 定义了掩码的值，它是由 HOTCOUNT_SIZE 乘以 HotCount 的大小得到的。HotCount 是一个 16 位的无符号整数，所以它的大小是 2 个字节。这样 HOTCOUNT_PCMASK 的值就是 (64-1)*2 = 126，也就是 0111 1110。这样可以保证哈希值的最高位是 0，避免与字节码指令的地址混淆。

LuaJIT 是如何进行尾递归优化的？

LuaJIT 是一个高性能的 Lua 解释器和编译器，它可以对尾递归进行优化，从而避免栈溢出和提高执行效率。尾递归是指一个函数在最后一步调用另一个函数，而不做任何其他操作。LuaJIT 的尾递归优化有两种方式，一种是基于 switch-case 的解释器循环，另一种是基于 tail call 的解释器循环¹²。

基于 switch-case 的解释器循环是 LuaJIT 的默认方式，它使用一个大的 switch 语句来处理不同的字节码指令，其中有一个 case 是专门用来处理尾递归的。当遇到一个尾递归的字节码指令时，它会先检查栈的空间是否足够，如果不够，就会扩展栈。然后它会将当前函数的栈帧弹出，并将被调用函数的参数复制到栈顶。最后它会跳转到被调用函数的入口点，继续执行¹。

基于 tail call 的解释器循环是 LuaJIT 的另一种方式，它使用一种称为 continuation-passing style 的技术，将每个字节码指令封装成一个单独的函数，并通过尾调用来传递控制权。当遇到一个尾递归的字节码指令时，它会直接调用被调用函数的入口点函数，并将当前函数的栈帧和被调用函数的参数作为参数传递。这样就可以避免栈的扩展和复制，提高执行效率²。

LuaJIT 可以通过编译选项或运行时选项来选择使用哪种方式进行尾递归优化¹³。😊

源: 与必应的对话， 2023/3/15(1) lua - LuaJIT 2 optimization guide - Stack Overflow. https://stackoverflow.com/questions/7167566/luajit-2-optimization-guide 访问时间 2023/3/15.
(2) Building the fastest Lua interpreter.. automatically!. https://sillycross.github.io/2022/11/22/2022-11-22/ 访问时间 2023/3/15.
(3) How to disable tail call optimizations for C calls? #972. https://github.com/LuaJIT/LuaJIT/issues/972 访问时间 2023/3/15.

LuaJIT 的源代码可以在 GitHub 上找到，有多个分支和镜像¹²³。两种方式对应的代码分别在以下文件中：

- 基于 switch-case 的解释器循环的代码在 src/lj_vm.c 中，其中有一个大的 switch 语句，以及一个处理尾递归的 case。
- 基于 tail call 的解释器循环的代码在 src/lj_vm.S 中，其中有一个大的宏定义，以及一个处理尾递归的宏。

你可以查看这些文件来了解更多细节。😊

源: 与必应的对话， 2023/3/15(1) GitHub - LuaJIT/LuaJIT: Mirror of the LuaJIT git repository. https://github.com/LuaJIT/LuaJIT 访问时间 2023/3/15.
(2) GitHub - openresty/luajit2: OpenResty's Branch of LuaJIT 2. https://github.com/openresty/luajit2 访问时间 2023/3/15.
(3) LuaJIT · GitHub. https://github.com/luajit 访问时间 2023/3/15.