import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("t3x1297", p)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_history = mod.load_history
mark_retired = mod.mark_retired
purge_retired = mod.purge_retired
active_modules = mod.active_modules

BASE = load_history(
    [
        ("chat_stack", "chat"),
        ("chat_api", "chat"),
        ("chat_ui", "chat"),
        ("core_engine", "core"),
        ("workflow_runner", "core"),
        ("export_tool", "core"),
    ],
    [
        ("chat_stack", "chat_api"),
        ("chat_stack", "chat_ui"),
    ],
    [
        ("workflow_runner", "chat_api"),
        ("export_tool", "core_engine"),
    ],
    [
        ("chat_api", "chat"),
        ("core_engine", "core"),
        ("workflow_runner", "chat"),
    ],
)
assert active_modules(BASE) == [
    "chat_api",
    "chat_stack",
    "chat_ui",
    "core_engine",
    "export_tool",
    "workflow_runner",
]
assert mark_retired(BASE, "chat_stack") == ["chat_api", "chat_stack", "chat_ui"]
assert active_modules(BASE) == ["core_engine", "export_tool", "workflow_runner"]
assert purge_retired(BASE) == ["workflow_runner"]
assert active_modules(BASE) == ["core_engine", "export_tool"]
assert mark_retired(BASE, "chat_stack") == []
assert purge_retired(BASE) == []

DIAMOND = load_history(
    [
        ("chat_stack", "chat"),
        ("chat_api", "chat"),
        ("sink_b", "core"),
        ("sink_c", "core"),
        ("sink_d", "core"),
    ],
    [("chat_stack", "chat_api")],
    [
        ("sink_d", "sink_c"),
        ("sink_d", "sink_b"),
        ("sink_c", "chat_api"),
        ("sink_b", "chat_api"),
    ],
    [("chat_api", "chat")],
)
mark_retired(DIAMOND, "chat_stack")
assert purge_retired(DIAMOND) == ["sink_b", "sink_c", "sink_d"]
assert active_modules(DIAMOND) == []

EMPTY = load_history([("only", "core")], [], [], [])
assert mark_retired(EMPTY, "missing") == []
assert purge_retired(EMPTY) == []
assert active_modules(EMPTY) == ["only"]
print("ok")
