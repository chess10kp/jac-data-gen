import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod636",
    Path(__file__).with_name("iss_The-Pipeline-Framework__pipelineframework__636.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_pipeline(
    [("state", None), ("query", "state"), ("decide", "query"), ("observe", "decide"), ("complete", "observe")],
    [("state", "query"), ("query", "decide"), ("decide", "observe"), ("observe", "complete")],
    [("state", "query"), ("query", "decide"), ("decide", "observe"), ("observe", "complete")],
    3,
)
assert mod.ancestor_chain(store, "complete") == ["state", "query", "decide", "observe", "complete"]
assert mod.reachable_via_spawn(store, "state") == ["complete", "decide", "observe", "query", "state"]
assert mod.ready_after_deps(store, ["state", "query"]) == ["decide"]
assert mod.bounded_turns(store, "state") == ["state", "query", "decide", "observe"]
print("ok")
