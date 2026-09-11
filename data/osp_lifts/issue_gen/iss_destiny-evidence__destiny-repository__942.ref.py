"""Reference harness: exercises every public function of iss_destiny-evidence__destiny-repository__942."""
import importlib

mod = importlib.import_module("iss_destiny-evidence__destiny-repository__942")
ConceptIndex = mod.ConceptIndex

cx = ConceptIndex()
# Four-level vocabulary, as in Health -> Outcomes -> NCD mortality -> Cardiovascular mortality.
cx.add_concept("health")
cx.add_concept("outcomes", "health")
cx.add_concept("ncd-mortality", "outcomes")
cx.add_concept("cardio-mortality", "ncd-mortality")
cx.add_concept("injury-mortality", "outcomes")
cx.add_concept("methods")

cx.code("ref-parent-only", "outcomes")
cx.code("ref-parent-and-child", "ncd-mortality")   # also coded at parent below
cx.code("ref-parent-and-child", "outcomes")
cx.code("ref-deep-only", "cardio-mortality")
cx.code("ref-sibling", "injury-mortality")
cx.code("ref-other", "methods")

# Exact mode: unchanged, level-exact behavior.
assert cx.count("outcomes") == 2
assert cx.filter_refs("outcomes") == ["ref-parent-and-child", "ref-parent-only"]
assert cx.count("cardio-mortality") == 1
assert cx.filter_refs("cardio-mortality") == ["ref-deep-only"]

# Rollup mode: parent stands for its whole subtree, no double counting.
assert cx.count("outcomes", rollup=True) == 4
assert cx.filter_refs("outcomes", rollup=True) == [
    "ref-deep-only", "ref-parent-and-child", "ref-parent-only", "ref-sibling"]
assert cx.count("ncd-mortality", rollup=True) == 2   # parent+child once, deep once
assert cx.count("health", rollup=True) == 4           # same set as outcomes rollup
assert cx.count("methods", rollup=True) == 1
assert cx.filter_refs("methods", rollup=True) == ["ref-other"]

# Count and filter always describe the same set of references.
for uri in ["health", "outcomes", "ncd-mortality", "cardio-mortality",
            "injury-mortality", "methods"]:
    assert cx.count(uri, rollup=True) == len(cx.filter_refs(uri, rollup=True))
    assert cx.count(uri) == len(cx.filter_refs(uri))

# Uncoded concept: zero everywhere.
cx.add_concept("empty-leaf", "health")
assert cx.count("empty-leaf") == 0
assert cx.count("empty-leaf", rollup=True) == 0
assert cx.filter_refs("empty-leaf", rollup=True) == []

# Unknown ids raise exactly like the source.
try:
    cx.count("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    cx.filter_refs("ghost", rollup=True)
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    cx.code("r", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    cx.add_concept("x", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Diamond coding still counts a reference once per concept rollup.
cx2 = ConceptIndex()
cx2.add_concept("top")
cx2.add_concept("l", "top")
cx2.add_concept("r", "top")
cx2.add_concept("bot", "l")
cx2.code("ra", "l")
cx2.code("ra", "r")          # two paths under top, one reference
cx2.code("rb", "bot")
assert cx2.count("top", rollup=True) == 2
assert cx2.count("l", rollup=True) == 2
assert cx2.filter_refs("top", rollup=True) == ["ra", "rb"]
