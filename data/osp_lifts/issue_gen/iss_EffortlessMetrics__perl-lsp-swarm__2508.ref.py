"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__2508."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__2508.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
SCOPES = ["pkg", "sub_a", "sub_b", "tok_hover", "tok_def"]
PARENT = [
  ("pkg", None),
  ("sub_a", "pkg"),
  ("sub_b", "pkg"),
  ("tok_hover", "sub_a"),
  ("tok_def", "sub_b"),
]
DEPENDS = [
  ("tok_hover", "sub_a"),
  ("tok_def", "sub_b"),
  ("sub_b", "sub_a"),
]
FACTS = {
  "pkg": "package:Main",
  "sub_a": "sub:name",
  "sub_b": "sub:other",
  "tok_hover": "hover:text",
  "tok_def": "def:other",
}
ANCHORS = {"pkg": 0, "sub_a": 10, "sub_b": 40, "tok_hover": 12, "tok_def": 42}

G = _mod.load_semantic_graph(SCOPES, PARENT, DEPENDS, FACTS, ANCHORS)

assert _mod.enclosing_scope_chain(G, "tok_hover") == ["tok_hover", "sub_a", "pkg"]
assert _mod.enclosing_scope_chain(G, "missing") == []

assert _mod.dependent_contributions(G, ["sub_a"]) == [
  "sub_a",
  "sub_b",
  "tok_hover",
]
assert _mod.dependent_contributions(G, ["ghost"]) == []

strat, facts, anchors = _mod.refresh_facts(G, ["sub_a"], "no_change")
assert strat == "retain"
assert facts == FACTS
assert anchors == ANCHORS

strat, facts, anchors = _mod.refresh_facts(G, ["sub_a"], "range_shift", shift=5)
assert strat == "rebase"
assert anchors["sub_a"] == 15
assert anchors["tok_hover"] == 12
assert facts == FACTS

strat, facts, anchors = _mod.refresh_facts(
  G,
  ["sub_a"],
  "body_change",
  recomputed={
    "sub_a": "sub:renamed",
    "sub_b": "sub:updated",
    "tok_hover": "hover:new",
  },
)
assert strat == "recompute"
assert facts == {
  "pkg": "package:Main",
  "sub_a": "sub:renamed",
  "sub_b": "sub:updated",
  "tok_hover": "hover:new",
  "tok_def": "def:other",
}
assert anchors == ANCHORS

strat, facts, anchors = _mod.refresh_facts(
  G,
  ["pkg"],
  "topology",
  recomputed={sid: f"new:{sid}" for sid in SCOPES},
)
assert strat == "fallback"
assert facts == {sid: f"new:{sid}" for sid in SCOPES}
assert anchors == ANCHORS

D_SCOPES = ["out", "leaf", "hub", "left", "right"]
D_PARENT = [
  ("out", None),
  ("leaf", "out"),
  ("hub", "out"),
  ("left", "hub"),
  ("right", "hub"),
]
D_DEPENDS = [
  ("hub", "right"),
  ("leaf", "left"),
  ("out", "leaf"),
  ("hub", "left"),
  ("leaf", "right"),
]
DG = _mod.load_semantic_graph(
  D_SCOPES,
  D_PARENT,
  D_DEPENDS,
  {sid: sid for sid in D_SCOPES},
  {sid: i * 10 for i, sid in enumerate(D_SCOPES)},
)
assert _mod.dependent_contributions(DG, ["left"]) == [
  "hub",
  "leaf",
  "left",
  "out",
]

CYG = _mod.load_semantic_graph(
  ["a", "b", "c"],
  [("a", "b"), ("b", "c"), ("c", "a")],
  [],
  {"a": "fa", "b": "fb", "c": "fc"},
  {"a": 1, "b": 2, "c": 3},
)
assert _mod.enclosing_scope_chain(CYG, "a") == ["a", "b", "c"]
print("iss_EffortlessMetrics__perl-lsp-swarm__2508 ref OK")
