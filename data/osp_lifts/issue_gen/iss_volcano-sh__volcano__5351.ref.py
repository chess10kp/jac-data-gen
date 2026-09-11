"""Reference harness: exercises every public function of iss_volcano-sh__volcano__5351."""
import importlib

mod = importlib.import_module("iss_volcano-sh__volcano__5351")
AdmissionError = mod.AdmissionError
QueueTree = mod.QueueTree

t = QueueTree()
t.add_queue("root")
for child in ["eng", "sci"]:
    t.add_queue(child, parent="root")
t.add_queue("ml", parent="eng")
t.add_queue("infra", parent="eng")
t.add_queue("physics", parent="sci")

# Close cascades synchronously to the entire subtree.
assert t.close_queue("root") == ["eng", "infra", "ml", "physics", "root", "sci"]
assert t.close_queue("root") == []          # idempotent
assert not t.is_open("physics")

# Open under a closed ancestor is rejected at admission.
try:
    t.open_queue("ml")
    raise SystemExit("expected AdmissionError")
except AdmissionError:
    pass

# Opening from the top re-enables everything beneath.
assert t.open_queue("root")
assert t.open_queue("eng")
assert t.open_queue("ml")
assert not t.is_open("infra")   # never explicitly reopened

# Partial close: only that subtree.
assert t.close_queue("eng") == ["eng", "ml"]   # infra already closed
try:
    t.open_queue("infra")
    raise SystemExit("expected AdmissionError")
except AdmissionError:
    pass
assert t.open_queue("sci")
assert t.descendants("root") == ["eng", "infra", "ml", "physics", "sci"]

# Foreground deletion requires a fully-closed subtree.
try:
    t.delete_queue_foreground("root")
    raise SystemExit("expected AdmissionError (subtree open)")
except AdmissionError:
    pass
assert t.close_queue("root") == ["root", "sci"]   # eng subtree already closed
removed = t.delete_queue_foreground("eng")
assert removed == ["eng", "infra", "ml"]
assert sorted(t.state_of.keys()) == ["physics", "root", "sci"]
assert t.children_of["root"] == ["sci"]     # detached cleanly

# Unknown parents and unknown queues fail directed.
u = QueueTree()
try:
    u.add_queue("x", parent="ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
u.add_queue("solo")
assert u.descendants("solo") == []
try:
    u.close_queue("nope")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Corrupt cycle in parent pointers terminates.
c = QueueTree()
c.parent_of["a"] = "b"
c.parent_of["b"] = "a"
c.children_of["a"] = ["b"]
c.children_of["b"] = ["a"]
c.state_of = {"a": "Open", "b": "Open"}
assert sorted(c._subtree("a")) == ["a", "b"]
assert c._ancestor_states("a") == ["Open"]  # stops without looping
