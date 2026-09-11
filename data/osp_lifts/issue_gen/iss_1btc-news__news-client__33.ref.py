import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_news_33",
    Path(__file__).with_name("iss_1btc-news__news-client__33.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_workflow(
    ["dri", "researcher", "writer", "inscriber"],
    [
        ("researcher", "writer"),
        ("writer", "inscriber"),
        ("dri", "researcher"),
        ("dri", "writer"),
    ],
)
assert mod.ready_roles(g) == ["dri"]
g2 = mod.load_workflow(
    ["dri", "researcher", "writer"],
    [("dri", "researcher"), ("researcher", "writer")],
    {"dri": "done"},
)
assert mod.ready_roles(g2) == ["researcher"]
assert mod.prerequisite_chain(g2, "writer") == ["dri", "researcher"]
print("ok")
