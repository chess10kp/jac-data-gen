"""Reference harness for iss_QwenLM__qwen-code__7272."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_QwenLM__qwen-code__7272.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
p = _mod.load_transcript_pipeline(
    [
        ("b1", "user", "hello"),
        ("b2", "assistant", "hi"),
        ("b3", "assistant", " there"),
    ],
    [("blocks", "display_items")],
)
assert _mod.downstream_stages(p, "blocks") == [
    "display_items",
    "merged_messages",
    "messages",
    "visible_items",
]
assert _mod.downstream_stages(p, "messages") == [
    "display_items",
    "merged_messages",
    "visible_items",
]
assert _mod.downstream_stages(p, "merged_messages") == ["display_items", "visible_items"]
assert _mod.downstream_stages(p, "visible_items") == []
assert _mod.downstream_stages(p, "ghost") == []
assert _mod.recompute_touch_count(p) == 15
assert _mod.stage_snapshot(p, "blocks") == [
    "user:b1:hello",
    "assistant:b2:hi",
    "assistant:b3: there",
]
assert _mod.stage_snapshot(p, "merged_messages") == [
    "merged:break:user:b1",
    "merged:break:assistant:b2",
    "merged:assistant:b3",
]
assert _mod.visible_items(p) == [
    "vis:disp:merged:break:user:b1",
    "vis:disp:merged:break:assistant:b2",
    "vis:disp:merged:assistant:b3",
]
assert _mod.streaming_tail_id(p) == "b3"
before = _mod.recompute_touch_count(p)
_mod.apply_block_delta(p, "b3", " there!")
assert _mod.recompute_touch_count(p) == 15
assert _mod.recompute_touch_count(p) > 0
assert _mod.stage_snapshot(p, "blocks")[-1] == "assistant:b3: there!"
assert _mod.visible_items(p)[-1] == "vis:disp:merged:assistant:b3"
_mod.apply_block_delta(p, "missing", "noop")
assert _mod.recompute_touch_count(p) == 15
assert _mod.stage_snapshot(p, "ghost") == []

p_sys = _mod.load_transcript_pipeline(
    [
        ("b1", "user", "hello"),
        ("s1", "system", "hidden"),
        ("b2", "assistant", "ok"),
    ],
    [("blocks", "display_items")],
)
assert _mod.stage_snapshot(p_sys, "display_items") == [
    "disp:merged:break:user:b1",
    "disp:merged:break:assistant:b2",
]
assert _mod.visible_items(p_sys) == [
    "vis:disp:merged:break:user:b1",
    "vis:disp:merged:break:assistant:b2",
]

rows = [(f"b{i}", "user" if i % 2 == 0 else "assistant", f"t{i}") for i in range(6)]
p_scale = _mod.load_transcript_pipeline(rows)
_mod.apply_block_delta(p_scale, "b5", "tail!")
assert _mod.recompute_touch_count(p_scale) == 30
assert _mod.streaming_tail_id(p_scale) == "b5"
print("iss_QwenLM__qwen-code__7272 ref OK")
