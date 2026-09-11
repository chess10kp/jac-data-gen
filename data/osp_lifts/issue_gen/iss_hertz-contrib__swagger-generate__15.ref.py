import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_hertz-contrib__swagger-generate__15",
    Path(__file__).with_name("iss_hertz-contrib__swagger-generate__15.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_messages = mod.load_messages
safe_schema_names = mod.safe_schema_names
has_cycle = mod.has_cycle

SELF = load_messages(["SelfReferencing"], [("SelfReferencing", "SelfReferencing")])
assert safe_schema_names(SELF, ["SelfReferencing"]) == ["SelfReferencing"]
assert has_cycle(SELF, "SelfReferencing") is True

TRI = load_messages(
    ["MessageA", "MessageB", "MessageC"],
    [("MessageA", "MessageB"), ("MessageB", "MessageC"), ("MessageC", "MessageA")],
)
assert safe_schema_names(TRI, ["MessageA"]) == ["MessageA", "MessageB", "MessageC"]
assert has_cycle(TRI, "MessageA") is True

CHAIN = load_messages(
    ["Root", "Mid", "Leaf"],
    [("Root", "Mid"), ("Mid", "Leaf")],
)
assert safe_schema_names(CHAIN, ["Root"]) == ["Leaf", "Mid", "Root"]
assert has_cycle(CHAIN, "Root") is False

DIAMOND = load_messages(
    ["A", "B", "C", "D"],
    [("A", "B"), ("A", "C"), ("B", "D"), ("C", "D")],
)
assert safe_schema_names(DIAMOND, ["A"]) == ["A", "B", "C", "D"]

assert safe_schema_names(CHAIN, ["missing"]) == []
assert has_cycle(CHAIN, "missing") is False

print("ok")
