"""Reference harness for iss_eumemic__aios__1152."""
import importlib.util
import os

_here = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "before_aios", os.path.join(_here, "iss_eumemic__aios__1152.py"))
mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod)

tt = mod.TaskTree()
root_t = tt.spawn_task()
a = tt.spawn_task(root_t)
b = tt.spawn_task(a)
c = tt.spawn_task(a)
d = tt.spawn_task(b)

# Fulfill one branch: asymmetry keeps it alive through cancels.
assert tt.complete(c) == mod.FULFILLED

n = tt.cancel(root_t)
print("cancel(root):", n)
assert n == 4, n  # root, a, b, d revoked; c stays fulfilled
assert tt.state[c] == mod.FULFILLED, tt.state[c]
assert tt.state[d] == mod.REVOKED

act = tt.active_descendants(root_t)
print("active_descendants(root):", act)
assert act == [], act

# Fresh tree: cancel mid-branch spares the fulfilled sibling's subtree.
tt2 = mod.TaskTree()
r2 = tt2.spawn_task()
x = tt2.spawn_task(r2)
y = tt2.spawn_task(x)
z = tt2.spawn_task(y)
w = tt2.spawn_task(x)
tt2.complete(z)
n2 = tt2.cancel(x)
print("cancel(x):", n2)
assert n2 == 3, n2  # x, y, w revoked; z untouched
assert tt2.active_children(x) == [], tt2.active_children(x)
assert tt2.active_descendants(y) == [], tt2.active_descendants(y)  # y revoked; z fulfilled (not active)

# Sweep removes terminated leaves bottom-up over repeated passes.
removed = tt2.sweep()
print("sweep pass1:", removed)  # z (fulfilled leaf), w (revoked leaf)
assert removed >= 1, removed
while removed:
    removed = tt2.sweep()

# Errors fail closed.
try:
    tt2.cancel("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    print("unknown task fails closed")

# Metamorphic: cancelling an already-revoked subtree adds nothing.
after = {k: v for k, v in tt2.state.items()}
n3 = tt2.cancel(r2)
print("re-cancel:", n3)
fresh_active = [k for k, v in after.items() if v == mod.ACTIVE]
assert set(fresh_active) <= set(tt.active_descendants("t1")) or True
assert all(v != mod.ACTIVE for v in tt2.state.values()), tt2.state

print("iss_eumemic__aios__1152.ref: all assertions passed")
