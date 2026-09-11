"""Reference harness: exercises every public function of iss_web3guru888__asi-build__280."""
import importlib

mod = importlib.import_module("iss_web3guru888__asi-build__280")
add_cause = mod.add_cause
add_trace = mod.add_trace
causes_of = mod.causes_of
effects_of = mod.effects_of
new_graph = mod.new_graph
roots_and_leaves = mod.roots_and_leaves


g = new_graph()
for t, phase in [("t1", "plan"), ("t2", "act"), ("t3", "verify"), ("t4", "report")]:
    add_trace(g, t, phase)
add_cause(g, "t1", "t2", 0.9)
add_cause(g, "t2", "t3", 0.8)
add_cause(g, "t1", "t3", 0.5)
add_cause(g, "t3", "t4", 0.7)

assert effects_of(g, "t1") == ["t2", "t3", "t4"]
assert causes_of(g, "t3") == ["t1", "t2"]
assert effects_of(g, "t4") == []
assert roots_and_leaves(g) == (["t1"], ["t4"])

# Cycle rejection, including self-loops.
try:
    add_cause(g, "t4", "t1")
    raise AssertionError("expected causal_cycle")
except ValueError as e:
    assert str(e) == "causal_cycle"
try:
    add_cause(g, "t2", "t2")
    raise AssertionError("expected causal_cycle")
except ValueError as e:
    assert str(e) == "causal_cycle"
# The rejected edges changed nothing.
assert effects_of(g, "t4") == []

# Diamond: shared intermediate appears once in closures.
d = new_graph()
add_trace(d, "r", "p")
add_trace(d, "m1", "p")
add_trace(d, "m2", "p")
add_trace(d, "z", "p")
add_cause(d, "r", "m1")
add_cause(d, "r", "m2")
add_cause(d, "m1", "z")
add_cause(d, "m2", "z")
assert effects_of(d, "r") == ["m1", "m2", "z"]
assert causes_of(d, "z") == ["m1", "m2", "r"]

print("iss_web3guru888__asi-build__280 ref OK")
