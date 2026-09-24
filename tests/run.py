"""Run with Python and lupa installed (uses a Lua 5.1 runtime)."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
import os
os.chdir(root)
for test in sorted((root / "tests").glob("*.lua")):
    runtime = LuaRuntime()
    runtime.execute(test.read_text())
for source in root.glob("*.lua"):
    LuaRuntime().eval("function(path) assert(loadfile(path)) end")(str(source))
print("All Lua tests and syntax checks passed")
