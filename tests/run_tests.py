"""Syntax-check every Lua file of a mod with Lua 5.1, then run the test files.

Usage: run_tests.py <mod media/lua dir> [<test.lua> ...]

Needs the lupa package (bundles Lua 5.1, like the game's Kahlua). Once, from the repo root:
    python3 -m venv .venv && .venv/bin/pip install "lupa==2.8"
    .venv/bin/python tests/run_tests.py ImperialUnits/Contents/mods/ImperialUnits/42.21/media/lua
Each test file runs in a fresh Lua state; the folder is the global MOD_LUA.
"""
import pathlib
import re
import sys

from lupa.lua51 import LuaError, LuaRuntime

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent

args = sys.argv[1:]
if not args:
    sys.exit(__doc__)
mod_lua = pathlib.Path(args[0])
tests = [pathlib.Path(p) for p in args[1:]] or sorted(HERE.glob("*_test.lua"))

bad = 0
for f in sorted(mod_lua.rglob("*.lua")):
    lua = LuaRuntime(unpack_returned_tuples=True)
    ok, err = lua.eval("function(s, n) local f, e = loadstring(s, n); return f ~= nil, e or '' end")(
        f.read_text(), "@" + f.name)
    if not ok:
        bad += 1
        print("SYNTAX ERROR", err)
    else:
        print("syntax ok   ", f.relative_to(mod_lua))

fails = 0
for test in tests:
    print("==", test.name)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().MOD_LUA = str(mod_lua)
    try:
        fails += lua.execute(test.read_text())
    except LuaError as e:
        # A Lua error stops that test file only: count it and run the others.
        fails += 1
        print("FAIL: Lua error, the rest of", test.name, "did not run:", str(e).splitlines()[0])
sys.exit(1 if bad or fails else 0)
