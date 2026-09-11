"""Reference harness: exercises every public function of iss_python__mypy__21123."""
import importlib

mod = importlib.import_module("iss_python__mypy__21123")
expand = mod.expand
expand_bounded = mod.expand_bounded

# simple table: alias parts mixed with terminals
T = {"A": ["int", "B"], "B": ["str"]}
assert expand("A", T) == ["int", "str"]
assert expand("B", T) == ["str"]
assert expand_bounded("A", T) == {"parts": ["int", "str"], "truncated": False}

# diamond: shared terminal reached via many paths collapses (dedup)
D = {"A": ["B", "C"], "B": ["T"], "C": ["B", "T"]}
assert expand("A", D) == ["T"]
assert expand_bounded("A", D, max_depth=4) == {"parts": ["T"], "truncated": False}

# terminal root and unknown names expand to themselves
assert expand("int", T) == ["int"]
assert expand("ghost", {}) == ["ghost"]
assert expand_bounded("ghost", {}, 3) == {"parts": ["ghost"], "truncated": False}

# deep chain: full expansion vs depth-capped partial expansion
chain = {f"c{i}": [f"c{i+1}"] for i in range(10)}  # c10 is a terminal
assert expand("c0", chain) == ["c10"]
assert expand_bounded("c0", chain, max_depth=10) == {"parts": ["c10"], "truncated": False}
assert expand_bounded("c0", chain, max_depth=9) == {"parts": [], "truncated": True}
assert expand_bounded("c0", chain, max_depth=5) == {"parts": [], "truncated": True}

# cyclic table: expand still crashes with RecursionError (pre-fix shape)
C = {"A": ["B"], "B": ["A"]}
try:
    expand("A", C)
    raise AssertionError("expected RecursionError")
except RecursionError:
    pass
try:
    expand("S", {"S": ["S"]})  # self-cycle
    raise AssertionError("expected RecursionError")
except RecursionError:
    pass

# cyclic table: the bounded walk terminates with the truncated flag
assert expand_bounded("A", C) == {"parts": [], "truncated": True}
assert expand_bounded("S", {"S": ["S"]}) == {"parts": [], "truncated": True}

# cycle with an escaping terminal branch: partial parts + truncated
E = {"A": ["B", "int"], "B": ["A"]}
try:
    expand("A", E)
    raise AssertionError("expected RecursionError")
except RecursionError:
    pass
assert expand_bounded("A", E) == {"parts": ["int"], "truncated": True}

print("iss_python__mypy__21123 ref OK")
