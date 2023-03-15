Path *src/luajit.c*

main

```c
  L = lua_open();
```

```c
  status = lua_cpcall(L, pmain, NULL); // ~~ 

```

lua_cpcall

```c
  status = lj_vm_cpcall(L, func, ud, cpcall); // ~~
```

lj_vm_cpcall->cpcall


in cpcall, lj_func_newC is called.

Path *src/lj_api.c*

```c
  GCfunc *fn = lj_func_newC(L, 0, getcurrenv(L)); 

```

in lj_func_newC, lj_mem_newgco is called.

```c
GCfunc *lj_func_newC(lua_State *L, MSize nelems, GCtab *env) 
{
  GCfunc *fn = (GCfunc *)lj_mem_newgco(L, sizeCfunc(nelems));
```

new gc object is allocated and marked white and appended to gch link list

back to lj_func_newC, fn is inited as a a GCfunc: 's gct is marked ~LJ_TFUNC. ffid marked FF_C. etc.

back to cpcall, set `fn->c.f = func;`

new func will inherent env. and its C pc is set to bc_cfunc_ext;	/* Bytecode for external C function calls. */

```C
setfuncV(L, top++, fn);
```
这行代码是一个宏定义，它表示将一个函数对象fn赋值给Lua状态L的栈顶元素，然后将栈顶指针向上移动一位1。它相当于以下两行代码：

L->top->u64 = fn->u64; L->top++;

这里的 hook_save hook_restore 是多余的吗？为什么要通过 lj_vm_cpcall 调用 cpcall，而不是直接调用？

我明白了，你是在看Luajit的源码。根据搜索结果¹，Luajit的lua_cpcall函数和Lua 5.1的lua_cpcall函数有一些不同，主要是为了提高性能和兼容性。hook_save和hook_restore函数是用于保存和恢复钩子函数的状态的，这可能是为了避免在保护模式下触发钩子函数或者影响错误处理¹。lj_vm_cpcall函数是一个宏，它会调用一个名为cpcall的汇编函数，这个函数会设置一个错误处理器，并执行传入的C函数²³。这样做可能是为了利用汇编代码的优化和异常处理机制¹。

你对这些解释满意吗？还是你想要更多的细节或者示例？或者你有其他的问题？

源: 与必应的对话， 2023/3/15(1) Alternative to the lua_cpcall(L, f, &x) pattern #255 - GitHub. https://github.com/LuaJIT/LuaJIT/issues/255 访问时间 2023/3/15.
(2) luajit/lj_vm.h at master · LuaDist/luajit · GitHub. https://github.com/LuaDist/luajit/blob/master/src/lj_vm.h 访问时间 2023/3/15.
(3) luajit/lj_load.c at master · LuaDist/luajit · GitHub. https://github.com/LuaDist/luajit/blob/master/src/lj_load.c 访问时间 2023/3/15.

vm_cpcall 和 vm_pcall 的区别是什么？

vm_cpcall:				// Setup protected C frame, call C.
vm_pcall:				// Setup protected C frame and enter VM.


pmain
    handle_script
        luaL_loadfile/luaL_loadfilex
            lua_loadx
                lj_vm_cpcall/cpparser
                    lj_lex_setup init lexer state
                        lj_parse
                            parse_chunk
                                parse_stmt
        docall
            lua_pcall base
                lj_vm_pcall ef
                    lj_vm_call
                        lj_vm_call_dispatch
                            lj_vmeta_call
                        lj_BC_IFUNCV
                        lj_BC_FUNCF
                            lj_vm_hotcall
            lua_remove base
            lua_gc
Path *src/lj_load.c*

```c
static TValue *cpparser(lua_State *L, lua_CFunction dummy, void *ud)
```

## #define curr_func(L) (&gcval(L->base-2)->fn) 这里为何 -2

因为一个 slot 的容量是 2（2-slot frame info）

LJ_FR2 是什么意思？

根据搜索结果¹²，LJ_FR2是一个宏，它表示是否使用两个字节码寄存器来存储64位的值，比如程序计数器或者引用。这个宏在LJ_GC64模式下是启用的，这样可以提高内存对齐和访问效率¹³。但是这也意味着在LJ_GC64模式下，字节码寄存器的压力会更大，所以需要增加LJ_MAX_SLOTS的值²。

你对这些解释满意吗？还是你想要更多的细节或者示例？或者你有其他的问题？

源: 与必应的对话， 2023/3/15(1) Finish LJ_GC64 mode · Issue #25 · LuaJIT/LuaJIT · GitHub. https://github.com/LuaJIT/LuaJIT/issues/25 访问时间 2023/3/15.
(2) LJ_MAX_SLOTS needs to be adjusted when LJ_FR2 is enabled #432. https://github.com/LuaJIT/LuaJIT/issues/432 访问时间 2023/3/15.
(3) Pointer alignment hack setting · Issue #209 · LuaJIT/LuaJIT. https://github.com/LuaJIT/LuaJIT/issues/209 访问时间 2023/3/15.

## gcval 宏

#define gcval(o)	((GCobj *)(gcrefu((o)->gcr) & LJ_GCVMASK))

#if LJ_GC64
#define gcval(o)	((GCobj *)(gcrefu((o)->gcr) & LJ_GCVMASK))
#else
#define gcval(o)	(gcref((o)->gcr))
#endif

这段代码是一个宏定义，它用于从一个TValue中获取一个GCobj的指针。如果LJ_GC64是启用的，那么它会先用gcrefu函数将TValue的gcr字段转换为一个无符号整数，然后用LJ_GCVMASK进行按位与运算，以去掉高位的标志位，最后将结果转换为一个GCobj的指针3。如果LJ_GC64是禁用的，那么它会直接用gcref函数将TValue的gcr字段转换为一个GCobj的指针3。

## GCHeader

#define GCHeader	GCRef nextgc; uint8_t marked; uint8_t gct

这段代码是一个宏定义，它表示每一个GC对象都要包含的三个字段¹³。GCRef是一个指向GC对象的引用，nextgc是一个指向下一个GC对象的引用，用于构成一个链表¹³。uint8_t是一个无符号的8位整数，marked表示这个GC对象的标记状态，用于垃圾回收算法¹³。gct表示这个GC对象的类型，比如字符串、表、函数等¹³。

你对这些解释满意吗？还是你想要更多的细节或者示例？或者你有其他的问题？

源: 与必应的对话， 2023/3/15(1) C#跟Lua如何超高性能传递数据 - 李嘉的博客 - 博客园. https://www.cnblogs.com/lijiajia/p/11219964.html 访问时间 2023/3/15.
(2) C#跟Lua如何超高性能传递数据 - 简书. https://www.jianshu.com/p/07586acf147d 访问时间 2023/3/15.
(3) Memory usage: #define vs. static const for uint8_t. https://arduino.stackexchange.com/questions/61970/memory-usage-define-vs-static-const-for-uint8-t 访问时间 2023/3/15.


## GCfuncHeader

#define GCfuncHeader \
  GCHeader; uint8_t ffid; uint8_t nupvalues; \
  GCRef env; GCRef gclist; MRef pc

这段代码是一个宏定义，它表示每一个GC函数对象都要包含的字段。它首先包含了GCHeader宏定义的三个字段，然后是一些函数对象特有的字段。ffid是一个无符号的8位整数，表示Fast function ID。nupvalues是一个无符号的8位整数，表示这个函数对象有多少个上值。env是一个指向GC对象的引用，表示这个函数对象的环境表。gclist是一个指向GC对象的引用，用于构成一个链表。pc是一个指向字节码指令的引用，表示这个函数对象的代码段。

#define FF_LUA		0
#define FF_C		1
#define isluafunc(fn)	((fn)->c.ffid == FF_LUA)
#define iscfunc(fn)	((fn)->c.ffid == FF_C)
#define isffunc(fn)	((fn)->c.ffid > FF_C)

## GCTab

typedef struct GCtab {
  GCHeader;
  uint8_t nomm;		/* Negative cache for fast metamethods. */
  int8_t colo;		/* Array colocation. */
  MRef array;		/* Array part. */
  GCRef gclist;
  GCRef metatable;	/* Must be at same offset in GCudata. */
  MRef node;		/* Hash part. */
  uint32_t asize;	/* Size of array part (keys [0, asize-1]). */
  uint32_t hmask;	/* Hash part mask (size of hash part - 1). */
#if LJ_GC64
  MRef freetop;		/* Top of free elements. */
#endif
} GCtab;
解释一下这些字段

这段代码是一个类型定义，它表示一个GC表对象的结构。它首先包含了GCHeader宏定义的三个字段，然后是一些表对象特有的字段。nomm是一个无符号的8位整数，表示这个表对象是否有快速元方法的负缓存。colo是一个有符号的8位整数，表示这个表对象的数组部分是否和另一个表对象共享内存。array是一个指向数组部分的引用，它存储了从0到asize-1的键值对。gclist是一个指向GC对象的引用，用于构成一个链表。metatable是一个指向GC对象的引用，表示这个表对象的元表。node是一个指向哈希部分的引用，它存储了其他的键值对。asize是一个无符号的32位整数，表示这个表对象的数组部分的大小。hmask是一个无符号的32位整数，表示这个表对象的哈希部分的掩码（哈希部分的大小减一）。如果使用了LJ_GC64编译选项，还有一个freetop字段，它是一个指向空闲元素的顶部的引用。


## lj_func_newC

GCfunc *lj_func_newC(lua_State *L, MSize nelems, GCtab *env) 

这段代码是一个函数定义，它表示创建一个新的C函数对象。它有三个参数：L是一个指向Lua状态的指针，nelems是一个无符号的16位整数，表示这个C函数对象的元素数量¹，env是一个指向GC表对象的指针，表示这个C函数对象的环境²。
C函数对象的元素数量，是指这个C函数对象可以存储的数据的数量。它和C函数对象的类型有关，比如C闭包对象，C原型对象，C轻量级函数对象等¹。不同类型的C函数对象有不同的元素数量，比如C闭包对象有一个元素，就是它的函数指针¹；C原型对象有多个元素，包括它的字节码，常量表，调试信息等¹；C轻量级函数对象没有元素，只有一个标识符¹。

利用 nelems 可以计算出这个C函数对象的大小，然后调用 lj_mem_newgco 函数分配内存，最后调用 lj_gc_check 函数检查内存是否足够。

## lj_mem_newgco

void * LJ_FASTCALL lj_mem_newgco(lua_State *L, GCSize size)

这段代码是一个函数定义，它表示分配一个新的GC对象。它有两个参数：L是一个指向Lua状态的指针，size是一个无符号的32位整数，表示这个GC对象的大小。

他的内部，通过 g->allocf 这个函数去分配。这个函数的一种实现如下：

```c
static void* l_alloc(void* ud, void* ptr, size_t osize, size_t nsize) {
  (void)ud;
  (void)osize;
  if (nsize == 0) {
    free(ptr);
    return NULL;
  } else
    return realloc(ptr, nsize);
}
```

这是 minilua 中的视线。ud 是一个指向全局状态的指针，ptr 是一个指向要分配的内存的指针，osize 是旧的内存大小，nsize 是新的内存大小。如果 nsize 为 0，表示释放内存，否则表示分配内存。

也会先用 LJ_ALLOCF_INTERNAL 占位，然后实际填充的函数可能是 lj_alloc_f

```c

void *lj_alloc_f(void *msp, void *ptr, size_t osize, size_t nsize)
{
  (void)osize;
  if (nsize == 0) {
    return lj_alloc_free(msp, ptr);
  } else if (ptr == NULL) {
    return lj_alloc_malloc(msp, nsize);
  } else {
    return lj_alloc_realloc(msp, ptr, nsize);
  }
}
```

这是 LuaJIT 的实现。msp 是一个指向全局状态的指针，ptr 是一个指向要分配的内存的指针，osize 是旧的内存大小，nsize 是新的内存大小。如果 nsize 为 0，表示释放内存，如果 ptr 为 NULL，表示分配内存，否则表示重新分配内存。

msp 全称 malloc_state pointer。

LuaJIT 内部实现了一个 Bundled memory allocator，基于 dlmalloc（Doug Lea's malloc） 修改而来。它的实现在 lj_alloc.c 中。

## lj_lightud_intern

Path *src/lj_udata.c*

```c
void *lj_lightud_intern(lua_State *L, void *p)
{
  global_State *g = G(L);
  uint64_t u = (uint64_t)p;
  uint32_t up = lightudup(u);
  uint32_t *segmap = mref(g->gc.lightudseg, uint32_t);
  MSize segnum = g->gc.lightudnum;
  if (segmap) {
    MSize seg;
    for (seg = 0; seg <= segnum; seg++)
      if (segmap[seg] == up)  /* Fast path. */
	return (void *)(((uint64_t)seg << LJ_LIGHTUD_BITS_LO) | lightudlo(u));
    segnum++;
    /* Leave last segment unused to avoid clash with ITERN key. */
    if (segnum >= (1 << LJ_LIGHTUD_BITS_SEG)-1) lj_err_msg(L, LJ_ERR_BADLU);
  }
  if (!((segnum-1) & segnum) && segnum != 1) {
    lj_mem_reallocvec(L, segmap, segnum, segnum ? 2*segnum : 2u, uint32_t);
    setmref(g->gc.lightudseg, segmap);
  }
  g->gc.lightudnum = segnum;
  segmap[segnum] = up;
  return (void *)(((uint64_t)segnum << LJ_LIGHTUD_BITS_LO) | lightudlo(u));
}
```


这是一个C函数，它的作用是将一个指针p转换为一个轻量级用户数据对象，并且将它存储在全局状态g的一个段映射表中¹。这样可以支持多个非零的47位段的轻量级用户数据对象¹。这个函数的参数是一个Lua状态L和一个指针p，它返回一个轻量级用户数据对象，它的类型是void *²。

你对这些解释满意吗？还是你想要更多的细节或者示例？或者你有其他的问题？

源: 与必应的对话， 2023/3/15(1) Support up to 3 non-zero 47-bit segments for lightuserdata. #581. https://github.com/LuaJIT/LuaJIT/pull/581 访问时间 2023/3/15.
(2) File: lj_udata.c | Debian Sources. https://sources.debian.org/src/luajit2/2.1-20230119-1/src/lj_udata.c/ 访问时间 2023/3/15.
(3) File: lj_udata.h | Debian Sources. https://sources.debian.org/src/luajit2/2.1-20220915-2~bpo11%2B1/src/lj_udata.h/ 访问时间 2023/3/15.

## LuaJIT 中的 lightuserdata 是什么？

根据搜索结果²，lightuserdata 是 Lua 中的一种数据类型，它表示一个 C 指针（也就是 void * 值）。它是一个值，不需要创建（就像我们不需要创建数字一样）。它和 full userdata 的区别是，lightuserdata 不受垃圾回收器管理，也不能有元表。

LuaJIT 的 FFI 库可以使用 lightuserdata 来表示 C 类型或外部符号¹。你可以用 ffi.cast 函数来把一个 lightuserdata 转换成一个 FFI 类型³。

源: 与必应的对话， 2023/3/15(1) Programming in Lua : 28.5. https://www.lua.org/pil/28.5.html 访问时间 2023/3/15.
(2) FFI Semantics - LuaJIT. https://luajit.org/ext_ffi_semantics.html 访问时间 2023/3/15.
(3) What is userdata and lightuserdata in Lua? - Stack Overflow. https://stackoverflow.com/questions/4329643/what-is-userdata-and-lightuserdata-in-lua 访问时间 2023/3/15.