"""Reference harness: exercises every public function of iss_richinmrudul__agentguard__182."""
from iss_richinmrudul__agentguard__182 import export_findings, load_reports, report_count

src = load_reports(
    {
        "suite": ["S:rule1"],
        "matrix": ["M:rule2"],
        "run_a": ["A:rule3", "A:rule4"],
        "run_b": ["B:rule5"],
    },
    [("suite", "run_a"), ("matrix", "run_a"), ("suite", "run_b")],
)

# run_a referenced by BOTH aggregates and also exported directly:
# its findings must appear exactly once.
assert export_findings(src, ["suite", "matrix", "run_a"]) == [
    ("matrix", "M:rule2"),
    ("run_a", "A:rule3"),
    ("run_a", "A:rule4"),
    ("run_b", "B:rule5"),
    ("suite", "S:rule1"),
]
assert report_count(src, ["suite", "matrix", "run_a"]) == 4

# Deep tree with a shared grandchild stays duplicate-free.
tree = load_reports(
    {"top": ["T:0"], "left": [], "right": [], "leaf": ["L:1"]},
    [("top", "left"), ("top", "right"), ("left", "leaf"), ("right", "leaf")],
)
assert export_findings(tree, ["top"]) == [("leaf", "L:1"), ("top", "T:0")]
assert report_count(tree, ["top"]) == 4

# Direct single-aggregate enrichment is untouched.
single = load_reports({"only": ["O:9"]}, [])
assert export_findings(single, ["only"]) == [("only", "O:9")]
assert report_count(single, ["only"]) == 1

print("iss_richinmrudul__agentguard__182 ref OK")
