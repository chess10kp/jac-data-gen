"""Reference harness: exercises every public function of iss_paperclipai__paperclip__4619."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "pc4619", Path(__file__).parent / "iss_paperclipai__paperclip__4619.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["pc4619"] = mod
spec.loader.exec_module(mod)

b = mod.IssueBoard()
b.add_issue(1, "root cause", "open")
b.add_issue(2, "symptom A", "blocked")
b.add_issue(3, "symptom B", "open")
b.add_issue(4, "crash", "blocked")
b.add_blocks(1, 2)
b.add_blocks(1, 3)
b.add_blocks(2, 4)

assert b.blocked_by(1) == [2, 3]
assert b.blockers_of(4) == [2]
assert b.first_blocked_chain(1) == [1, 2, 4], b.first_blocked_chain(1)
assert b.first_blocked_chain(3) == [3]
assert b.unblockable(1) == [1, 3], b.unblockable(1)

# The issue's crash: circular dependency must terminate.
c = mod.IssueBoard()
c.add_issue("A", "a", "blocked")
c.add_issue("B", "b", "blocked")
c.add_issue("C", "c", "open")
c.add_blocks("A", "B")
c.add_blocks("B", "A")   # the hostile merge: A blocks B blocks A
c.add_blocks("A", "C")

chain = c.first_blocked_chain("A")
assert chain == ["A", "B"], chain          # stops at first revisit
assert c.first_blocked_chain("C") == ["C"]
assert c.unblockable("A") == ["C"], c.unblockable("A")

# Deep chain stays linear.
d = mod.IssueBoard()
prev = None
for i in range(50):
    d.add_issue(i, str(i), "open" if i else "blocked")
    if prev is not None:
        d.add_blocks(prev, i)
    prev = i
assert len(d.first_blocked_chain(0)) == 50
assert d.unblockable(0)[0] == 1 and len(d.unblockable(0)) == 49

# Errors.
try:
    b.add_blocks(1, 99)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    b.add_issue(1, "dup")
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("paperclip 4619 ref OK")
