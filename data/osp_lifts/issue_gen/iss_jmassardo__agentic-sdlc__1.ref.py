import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_jmassardo__agentic-sdlc__1",
    Path(__file__).with_name("iss_jmassardo__agentic-sdlc__1.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

STORE = mod.load_agents(
    ["dispatcher", "architecture", "development", "reviewer", "quality"],
    [
        ("dispatcher", "architecture"),
        ("architecture", "development"),
        ("development", "reviewer"),
        ("reviewer", "quality"),
        ("quality", "development"),
    ],
)
assert mod.reachable_agents(STORE, "dispatcher") == [
    "architecture",
    "development",
    "dispatcher",
    "quality",
    "reviewer",
]
assert mod.detect_handoff_cycles(STORE) == [("quality", "development")]
assert mod.reachable_agents(STORE, "ghost") == []
print("ok")
