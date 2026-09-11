"""Reference harness for iss_Comfy-Org__ComfyUI__15517."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Comfy-Org__ComfyUI__15517.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
store = _mod.make_patcher_store(
    {
        "unet.conv_in": 1.0,
        "unet.mid": 2.0,
        "unet.conv_out": 3.0,
        "vae.decode": 4.0,
    },
    [
        ("unet.mid", "unet.conv_in"),
        ("unet.conv_out", "unet.mid"),
        ("vae.decode", "unet.conv_out"),
    ],
)
_mod.backup_weight(store, "unet.conv_in")
_mod.backup_weight(store, "unet.mid", inplace=True)
_mod.backup_weight(store, "unet.conv_out")
assert _mod.backup_entry_count(store) == 3
assert _mod.unique_backup_entry_types(store) == 3
assert _mod.workflow_downstream(store, "unet.conv_in") == [
    "unet.conv_out",
    "unet.mid",
    "vae.decode",
]
assert _mod.weight_parent_chain(store, "vae.decode") == [
    "unet.conv_out",
    "unet.mid",
    "unet.conv_in",
]
assert _mod.cycle_member_weights(store) == []

_mod.clear_backups(store)
assert _mod.backup_entry_count(store) == 0
assert _mod.unique_backup_entry_types(store) == 0

diamond = _mod.make_patcher_store(
    {"root": 0.0, "left": 0.0, "right": 0.0, "join": 0.0},
    [
        ("join", "right"),
        ("left", "root"),
        ("right", "root"),
        ("join", "left"),
    ],
)
assert _mod.workflow_downstream(diamond, "root") == ["join", "left", "right"]
assert _mod.weight_parent_chain(diamond, "join") == ["right", "root"]

cycle = _mod.make_patcher_store(
    {"a": 0.0, "b": 0.0, "c": 0.0},
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert _mod.cycle_member_weights(cycle) == ["a", "b", "c"]

_mod.backup_weight(cycle, "a")
_mod.backup_weight(cycle, "b")
assert _mod.backup_entry_count(cycle) == 2
assert _mod.unique_backup_entry_types(cycle) == 2

assert _mod.workflow_downstream(store, "missing") == []
assert _mod.weight_parent_chain(store, "missing") == []
assert _mod.cycle_member_weights(_mod.make_patcher_store({}, [])) == []
_mod.backup_weight(store, "missing")
assert _mod.backup_entry_count(store) == 0
print("iss_Comfy-Org__ComfyUI__15517 ref OK")
