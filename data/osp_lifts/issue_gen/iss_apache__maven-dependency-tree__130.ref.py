"""Reference harness: exercises every public function of iss_apache__maven-dependency-tree__130."""
import importlib

mod = importlib.import_module("iss_apache__maven-dependency-tree__130")
collect = mod.collect
collect_iter = mod.collect_iter
count_nodes = mod.count_nodes

# Classic diamond: a shared dep reachable by two paths is collected once.
diamond = {
    "root": ["left", "right"],
    "left": ["shared", "extra"],
    "right": ["shared"],
    "extra": [],
    "shared": [],
}
assert collect(diamond, "root") == ["extra", "left", "right", "root", "shared"]
assert collect_iter(diamond, "root") == ["extra", "left", "right", "root", "shared"]
assert count_nodes(diamond, "root") == 5

# Shallow tree: the recursive path is safe below the stack limit.
tree = {"app": ["web", "db"], "web": ["util"], "db": ["util", "log"], "util": ["log"], "log": []}
assert collect(tree, "app") == ["app", "db", "log", "util", "web"]
assert collect_iter(tree, "app") == ["app", "db", "log", "util", "web"]
assert count_nodes(tree, "app") == 5

# Deep chain, 5,000 levels: the iterative walk resolves it without recursion.
# The recursive collect is the crashing code path, so it is not exercised here.
deep = {f"n{i}": [f"n{i+1}"] for i in range(5000)}
deep["n5000"] = []
res = collect_iter(deep, "n0")
assert len(res) == 5001 and set(res) == {f"n{i}" for i in range(5001)}
assert count_nodes(deep, "n0") == 5001

# Cyclic chain (a -> b -> c -> b) terminates via the seen set.
cyc = {"a": ["b"], "b": ["c"], "c": ["b"]}
assert collect(cyc, "a") == ["a", "b", "c"]
assert collect_iter(cyc, "a") == ["a", "b", "c"]
assert count_nodes(cyc, "a") == 3

# Adversarial edge order: the shared child is wired before deeper first-visits,
# so a revisit fires while unvisited artifacts are still pending.
adv = {"root": ["shared", "mid"], "mid": ["shared", "deep"], "shared": ["deep"], "deep": []}
assert collect(adv, "root") == collect_iter(adv, "root") == ["deep", "mid", "root", "shared"]
assert count_nodes(adv, "root") == 4

# Unknown root: tolerated, the closure is the lone root.
g = {"a": ["b"], "b": []}
assert collect(g, "ghost") == ["ghost"]
assert collect_iter(g, "ghost") == ["ghost"]
assert count_nodes(g, "ghost") == 1

print("iss_apache__maven-dependency-tree__130 ref OK")
