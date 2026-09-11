"""Reference harness: exercises every public function of iss_bh679__AutoClaude__12."""
import importlib

mod = importlib.import_module("iss_bh679__AutoClaude__12")
new_queue = mod.new_queue
add_task = mod.add_task
update_task = mod.update_task
complete_task = mod.complete_task
get_next_approved = mod.get_next_approved
waiting_for = mod.waiting_for
dependents = mod.dependents
CircularDependencyError = mod.CircularDependencyError

q = new_queue()
add_task(q, "a")
add_task(q, "b", deps=["a"])
add_task(q, "c", deps=["b", "a"])

# Gating: b waits for a; c waits for b and a.
assert get_next_approved(q) == "a"
assert waiting_for(q, "c") == ["a", "b"]
assert dependents(q, "a") == ["b", "c"]
assert dependents(q, "c") == []

# Unknown dependency reference rejected.
try:
    add_task(q, "d", deps=["zzz"])
    raise AssertionError("expected KeyError")
except KeyError:
    pass

# Self-dependency rejected at creation.
try:
    add_task(q, "e", deps=["e"])
    raise AssertionError("expected CircularDependencyError")
except CircularDependencyError:
    pass

# Transitive cycle closed via update rejected, state preserved.
add_task(q, "x")
add_task(q, "y", deps=["x"])
add_task(q, "z", deps=["y"])
try:
    update_task(q, "x", deps=["z"])  # x->z->y->x closes the loop
    raise AssertionError("expected CircularDependencyError")
except CircularDependencyError:
    pass
assert waiting_for(q, "x") == []
assert dependents(q, "x") == ["y", "z"]
try:
    update_task(q, "x", deps=["ghost"])
    raise AssertionError("expected KeyError")
except KeyError:
    pass
update_task(q, "z", deps=["x"])  # legal rewire: drop y, depend on x only
assert waiting_for(q, "z") == ["x"]

# Completion flows through the chain.
assert complete_task(q, "a") == "a"
assert get_next_approved(q) == "b"
assert waiting_for(q, "b") == []
assert waiting_for(q, "c") == ["b"]
complete_task(q, "b")
assert get_next_approved(q) == "c"
assert complete_task(q, "nobody") is None
complete_task(q, "c")
assert get_next_approved(q) == "x"  # lowest eligible id

# Duplicate registration rejected.
try:
    add_task(q, "a")
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("iss_bh679__AutoClaude__12 ref OK")
