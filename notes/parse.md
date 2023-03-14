# Parse 过程

首先进入程序

*src/luajit.c* 569:

```c
int main(int argc, char **argv)
{
  int status;
  lua_State *L;
  if (!argv[0]) argv = empty_argv; else if (argv[0][0]) progname = argv[0];
  L = lua_open();
  if (L == NULL) {
    l_message("cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  smain.argc = argc;
  smain.argv = argv;
  status = lua_cpcall(L, pmain, NULL); // <----------------
  report(L, status);
  lua_close(L);
  return (status || smain.status > 0) ? EXIT_FAILURE : EXIT_SUCCESS;
}
```

*src/lj_api.c* 1166:

```c
LUA_API int lua_cpcall(lua_State *L, lua_CFunction func, void *ud)
{
  global_State *g = G(L);
  uint8_t oldh = hook_save(g);
  int status;
  lj_checkapi(L->status == LUA_OK || L->status == LUA_ERRERR,
	      "thread called in wrong state %d", L->status);
  status = lj_vm_cpcall(L, func, ud, cpcall); // <----------------
  if (status) hook_restore(g, oldh);
  return status;
}
```
