"""Reference harness: exercises every public function of iss_OrpingtonClose__MiroThinker__226."""
import importlib

mod = importlib.import_module("iss_OrpingtonClose__MiroThinker__226")
lineage = mod.lineage
synthesis_depth = mod.synthesis_depth
priority = mod.priority

F = [
    {"id": "f1", "cluster": 7, "weight": 10, "parent_ids": []},
    {"id": "f2", "cluster": 7, "weight": 4, "parent_ids": []},
    {"id": "s1", "cluster": 7, "weight": 6, "parent_ids": ["f1", "f2"]},
    {"id": "f3", "cluster": 12, "weight": 3, "parent_ids": []},
    {"id": "s2", "cluster": 12, "weight": 8, "parent_ids": ["s1", "f3"]},
    {"id": "s3", "cluster": 12, "weight": 5, "parent_ids": ["s2"]},
]

# lineage: full ancestry, second-order synthesis included
assert lineage(F, "s3") == ["f1", "f2", "f3", "s1", "s2"]
assert lineage(F, "s2") == ["f1", "f2", "f3", "s1"]
assert lineage(F, "f1") == []

# depth cap: hop counts s2=1, s1=f3=2, f1=f2=3 from s3
assert lineage(F, "s3", max_depth=0) == []
assert lineage(F, "s3", max_depth=1) == ["s2"]
assert lineage(F, "s3", max_depth=2) == ["f3", "s1", "s2"]
assert lineage(F, "s3", max_depth=3) == ["f1", "f2", "f3", "s1", "s2"]

# adversarial-order diamond: long branch listed before the direct parent,
# so the shared ancestor is first reached deep and must improve to shallow
D = [
    {"id": "x3", "cluster": 1, "weight": 1, "parent_ids": []},
    {"id": "x1", "cluster": 1, "weight": 1, "parent_ids": ["x3"]},
    {"id": "x0", "cluster": 1, "weight": 1, "parent_ids": ["x1", "x3"]},
]
assert lineage(D, "x0", max_depth=1) == ["x1", "x3"]  # x3 counts at 1 hop, not 2
assert lineage(D, "x0") == ["x1", "x3"]

# deeper improvement: yM reachable at 2 (short) and 4 (long, listed first)
D2 = [
    {"id": "yM", "cluster": 1, "weight": 1, "parent_ids": []},
    {"id": "yD", "cluster": 1, "weight": 1, "parent_ids": ["yM"]},
    {"id": "yC", "cluster": 1, "weight": 1, "parent_ids": ["yD"]},
    {"id": "yB", "cluster": 1, "weight": 1, "parent_ids": ["yC"]},
    {"id": "yA", "cluster": 1, "weight": 1, "parent_ids": ["yM"]},
    {"id": "y0", "cluster": 1, "weight": 1, "parent_ids": ["yB", "yA"]},
]
assert lineage(D2, "y0", max_depth=2) == ["yA", "yB", "yC", "yM"]
assert lineage(D2, "y0", max_depth=3) == ["yA", "yB", "yC", "yD", "yM"]
assert lineage(D2, "y0") == ["yA", "yB", "yC", "yD", "yM"]

# parent loop terminates via the depth bookkeeping
C = [
    {"id": "c2", "cluster": 1, "weight": 1, "parent_ids": ["c1"]},
    {"id": "c1", "cluster": 1, "weight": 1, "parent_ids": ["c2"]},
    {"id": "c0", "cluster": 1, "weight": 1, "parent_ids": ["c1"]},
]
assert lineage(C, "c0") == ["c1", "c2"]

# unknown parent refs are skipped; unknown root raises KeyError
G = [
    {"id": "g1", "cluster": 1, "weight": 1, "parent_ids": ["ghost", "g0"]},
    {"id": "g0", "cluster": 1, "weight": 1, "parent_ids": []},
]
assert lineage(G, "g1") == ["g0"]
for fn in (lineage, synthesis_depth, priority):
    try:
        fn(G, "ghost")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

# synthesis_depth: longest root chain (memoized recursion above)
assert synthesis_depth(F, "f1") == 0
assert synthesis_depth(F, "s1") == 1
assert synthesis_depth(F, "s2") == 2
assert synthesis_depth(F, "s3") == 3
Z = [  # diamond: both chains length 2
    {"id": "t", "cluster": 1, "weight": 1, "parent_ids": []},
    {"id": "a", "cluster": 1, "weight": 1, "parent_ids": ["t"]},
    {"id": "b", "cluster": 1, "weight": 1, "parent_ids": ["t"]},
    {"id": "z", "cluster": 1, "weight": 1, "parent_ids": ["a", "b"]},
]
assert synthesis_depth(Z, "z") == 2
W = [  # long chain listed before the short one
    {"id": "q", "cluster": 1, "weight": 1, "parent_ids": []},
    {"id": "v", "cluster": 1, "weight": 1, "parent_ids": ["q"]},
    {"id": "u", "cluster": 1, "weight": 1, "parent_ids": ["v"]},
    {"id": "ps", "cluster": 1, "weight": 1, "parent_ids": ["q"]},
    {"id": "w", "cluster": 1, "weight": 1, "parent_ids": ["u", "ps"]},
]
assert synthesis_depth(W, "w") == 3

# priority: boost applies only at depth >= 2
assert priority(F, "f3") == 3
assert priority(F, "s1") == 6
assert priority(F, "s2") == 13  # 8 + 5
assert priority(F, "s3") == 10  # 5 + 5

print("iss_OrpingtonClose__MiroThinker__226 ref OK")
