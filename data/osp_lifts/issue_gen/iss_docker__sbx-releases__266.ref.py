import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_docker__sbx-releases__266",
    Path(__file__).with_name("iss_docker__sbx-releases__266.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_tree(
    [
        ("/ws", "dir"),
        ("/ws/node_modules", "dir"),
        ("/ws/node_modules/typescript", "dir"),
        ("/ws/node_modules/typescript/lib", "dir"),
        ("/ws/node_modules/typescript/lib/tsc.js", "file"),
    ],
    [
        ("/ws", "/ws/node_modules"),
        ("/ws/node_modules", "/ws/node_modules/typescript"),
        ("/ws/node_modules/typescript", "/ws/node_modules/typescript/lib"),
        ("/ws/node_modules/typescript/lib", "/ws/node_modules/typescript/lib/tsc.js"),
    ],
)
assert mod.subtree_file_count(store, "/ws") == 1
assert "/ws/node_modules/typescript/lib/tsc.js" in mod.subtree_paths(store, "/ws")
assert mod.max_depth(store, "/ws") == 4
assert mod.entry_kind(store, "/ws/node_modules/typescript/lib/tsc.js") == "file"
print("ok")
