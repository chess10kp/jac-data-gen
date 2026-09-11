"""Reference harness: exercises every public function of iss_Growth-Circle__cadis__403."""
import importlib

mod = importlib.import_module("iss_Growth-Circle__cadis__403")
agent_depth = mod.agent_depth
chain_of = mod.chain_of
cycle_in = mod.cycle_in
load_agents = mod.load_agents
MAX_CHAIN = mod.MAX_CHAIN

# Linear lineage: a1 <- a2 <- a3 (a3's parent is a2, ...)
reg = load_agents({"a1": None, "a2": "a1", "a3": "a2"})
assert chain_of(reg, "a3") == ["a3", "a2", "a1"]
assert chain_of(reg, "a1") == ["a1"]
assert agent_depth(reg, "a3") == 2
assert agent_depth(reg, "a1") == 0
assert cycle_in(reg, "a3") is None

# Unknown agent id: zero-depth, empty chain (source's get() miss).
assert agent_depth(reg, "ghost") == 0
assert chain_of(reg, "ghost") == []

# Dangling parent reference (corrupt state): chain ends at the known part.
dang = load_agents({"a1": "missing", "a2": "a1"})
assert chain_of(dang, "a2") == ["a2", "a1"]
assert agent_depth(dang, "a2") == 1
assert cycle_in(dang, "a2") is None

# Two-node mutual cycle: loop must break, chain reported, not spin forever.
mutual = load_agents({"A": "B", "B": "A"})
assert agent_depth(mutual, "A") == 1
assert chain_of(mutual, "A") == ["A", "B"]
assert cycle_in(mutual, "A") == ["A", "B"]
assert cycle_in(mutual, "B") == ["B", "A"]

# Self-parent: single-member cycle.
selfp = load_agents({"S": "S"})
assert chain_of(selfp, "S") == ["S"]
assert cycle_in(selfp, "S") == ["S"]
assert agent_depth(selfp, "S") == 0

# Three-node cycle entered mid-chain.
tri = load_agents({"ok": None, "c1": "ok", "c2": "c1", "c3": "c2", "c1b": None})
tri2 = load_agents({"A": "B", "B": "C", "C": "A", "pre": "A"})
assert cycle_in(tri2, "pre") == ["A", "B", "C"]
assert chain_of(tri2, "pre") == ["pre", "A", "B", "C"]

# Cap: a chain longer than MAX_CHAIN truncates instead of spinning.
long_parents = {f"n{i}": f"n{i-1}" for i in range(1, MAX_CHAIN + 10)}
long_parents["n0"] = None
deep = load_agents(long_parents)
assert agent_depth(deep, f"n{MAX_CHAIN + 9}") == MAX_CHAIN - 1
assert cycle_in(deep, f"n{MAX_CHAIN + 9}") is None

# Root-only registry.
solo = load_agents({"only": None})
assert agent_depth(solo, "only") == 0

print("iss_Growth-Circle__cadis__403 ref OK")
