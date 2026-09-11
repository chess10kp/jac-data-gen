"""Reference harness: exercises every public function of iss_KaviiSuri__bb-plugin-tasks__1."""
import importlib

mod = importlib.import_module("iss_KaviiSuri__bb-plugin-tasks__1")
Board = mod.Board

b = Board()
for t in ["epic", "sub", "design", "impl", "test", "release"]:
    b.add_task(t)
b.add_task("done_thing", status="done")

b.link("design", "impl")
b.link("impl", "test")
b.link("test", "release")

# Derived blocking is direct-only; chains are not flattened.
assert b.is_blocked("impl") and b.is_blocked("test")
assert not b.is_blocked("epic")            # no deps at all
assert b.unresolved_blocker_count("impl") == 1
b.link("design", "test")
assert b.unresolved_blocker_count("test") == 2
assert not b.is_blocked("release") is False

# Completing a blocker unblocks direct dependents only.
touched = b.complete("design")
assert touched == {"impl": [], "test": ["impl"]}   # sweep is direct-only
assert not b.is_blocked("impl")
assert b.is_blocked("test")               # still blocked by impl
assert b.status_of["design"] == "done"    # badge never replaces status

# Reopening re-blocks dependents.
touched = b.reopen("design")
assert touched == {"impl": ["design"], "test": ["design", "impl"]}
assert b.is_blocked("impl")

# Cancel resolves the edge, but test stays blocked by the reopened design.
touched = b.cancel("impl")
assert touched == {"test": ["design"]}
assert b.is_blocked("test")
b.complete("design")
assert not b.is_blocked("test")

# Linking to a terminal task is allowed and its edge is resolved.
b.link("release", "done_thing")
assert not b.is_blocked("done_thing")

# Transactional rejection: self, duplicate, unknown, cycle.
try:
    b.link("test", "test")
    raise SystemExit("expected self-link reject")
except ValueError:
    pass
try:
    b.link("design", "impl")
    raise SystemExit("expected duplicate reject")
except ValueError:
    pass
try:
    b.link("ghost", "impl")
    raise SystemExit("expected unknown reject")
except KeyError:
    pass
try:
    b.link("release", "design")   # release -> design closes a cycle
    raise SystemExit("expected cycle reject")
except ValueError:
    pass
try:
    # Cycle through a RESOLVED edge: release blocks done_thing even though
    # done_thing is terminal; closing the loop back into design must fail.
    b.link("done_thing", "design")
    raise SystemExit("expected resolved-edge cycle reject")
except ValueError:
    pass

# blocked_tasks view: canceled impl never shows as blocked even after its
# blocker reopens; release is still blocked by nonterminal test.
assert b.blocked_tasks() == ["release"]
b.reopen("design")                       # re-blocks test directly
assert b.blocked_tasks() == ["release", "test"]
b.reopen("impl")                         # canceled -> still excluded
assert b.blocked_tasks() == ["impl", "release", "test"]
assert "done_thing" not in b.blocked_tasks()

# Corrupt adjacency (imported cycle) does not hang the DFS.
c = Board()
c.add_task("p")
c.add_task("q")
c.dependents_of["p"].add("q")
c.dependents_of["q"].add("p")
assert c._reaches("p", "q")
