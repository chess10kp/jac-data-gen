"""Reference harness for iss_dotnet__runtime__132559."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_dotnet__runtime__132559.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
G = load_aot_generic_graph(
  [
    ("A0A1`1", "A0`1"),
    ("A0`1", "Base`0"),
    ("Base`0", ""),
    ("VerifyGeneric`1", "Base`0"),
  ],
  ["restore", "build_coreclr", "aot_compile", "JIT.Generics_ro"],
  [
    ("aot_compile", "build_coreclr"),
    ("aot_compile", "restore"),
    ("JIT.Generics_ro", "aot_compile"),
  ],
)

assert transitive_bases(G, "A0A1`1") == ["A0`1", "Base`0"]
assert transitive_bases(G, "Base`0") == []
assert transitive_bases(G, "VerifyGeneric`1") == ["Base`0"]
assert transitive_bases(G, "missing") == []

assert recursive_generic_types(G) == []

assert transitive_build_prereqs(G, "JIT.Generics_ro") == [
  "aot_compile",
  "build_coreclr",
  "restore",
]
assert transitive_build_prereqs(G, "restore") == []
assert transitive_build_prereqs(G, "ghost") == []

assert build_prereq_paths(G, "JIT.Generics_ro", "restore") == [
  ["JIT.Generics_ro", "aot_compile", "restore"],
]
assert build_prereq_paths(G, "JIT.Generics_ro", "build_coreclr") == [
  ["JIT.Generics_ro", "aot_compile", "build_coreclr"],
]
assert build_prereq_paths(G, "missing", "restore") == []
assert build_prereq_paths(G, "JIT.Generics_ro", "ghost") == []

CYC = load_aot_generic_graph(
  [
    ("A0A1`1", "A1`1"),
    ("A1`1", "A0`1"),
    ("A0`1", "A0A1`1"),
  ],
  ["aot_compile"],
  [],
)
assert recursive_generic_types(CYC) == ["A0`1", "A0A1`1", "A1`1"]
assert transitive_bases(CYC, "A0A1`1") == ["A0`1", "A0A1`1", "A1`1"]

DIAM = load_aot_generic_graph(
  [],
  ["root", "left", "right", "sink"],
  [
    ("sink", "right"),
    ("sink", "left"),
    ("left", "root"),
    ("right", "root"),
  ],
)
assert build_prereq_paths(DIAM, "sink", "root") == [
  ["sink", "left", "root"],
  ["sink", "right", "root"],
]
assert transitive_build_prereqs(DIAM, "sink") == ["left", "right", "root"]

BUILD_CYC = load_aot_generic_graph(
  [],
  ["a", "b", "c"],
  [("a", "b"), ("b", "c"), ("c", "a")],
)
assert transitive_build_prereqs(BUILD_CYC, "a") == ["a", "b", "c"]
assert build_prereq_paths(BUILD_CYC, "a", "a") == [["a"]]
assert build_prereq_paths(BUILD_CYC, "a", "c", max_depth=2) == []
assert build_prereq_paths(BUILD_CYC, "a", "c", max_depth=3) == [["a", "b", "c"]]

assert recursive_generic_types(load_aot_generic_graph([], [], [])) == []
print("iss_dotnet__runtime__132559 ref OK")
