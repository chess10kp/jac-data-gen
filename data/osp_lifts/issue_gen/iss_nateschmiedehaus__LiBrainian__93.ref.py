"""Reference harness: exercises every public function of iss_nateschmiedehaus__LiBrainian__93."""
import importlib

mod = importlib.import_module("iss_nateschmiedehaus__LiBrainian__93")
mark_dirty = mod.mark_dirty
recompute = mod.recompute

# --- mark_dirty -----------------------------------------------------------
# Leaf change (nothing depends on it): only that pack dirties.
leaf = {"a": [], "b": []}
assert mark_dirty(leaf, ["a"]) == ["a"]

# Chain: util <- lib <- app dirties the whole downstream path.
chain = {"app": ["lib"], "lib": ["util"], "util": []}
assert mark_dirty(chain, ["util"]) == ["app", "lib", "util"]

# Adversarial-order diamond: app's dep on util declared before lib, so app is
# dirtied via util before core's first visit through lib -- each pack once.
dia = {"app": ["util", "lib"], "lib": ["core"], "util": ["core"], "core": []}
assert mark_dirty(dia, ["core"]) == ["app", "core", "lib", "util"]

# Cycles terminate: whole SCC plus its dependents dirty.
cyc = {"a": ["b"], "b": ["a"], "c": ["a"]}
assert mark_dirty(cyc, ["a"]) == ["a", "b", "c"]

# Ghost seed is ignored; a dep-name-only seed still propagates.
gen = {"app": ["shared"], "shared": []}
assert mark_dirty(gen, ["ghost"]) == []
assert mark_dirty(gen, ["shared"]) == ["app", "shared"]

# --- recompute ------------------------------------------------------------
# Full cascade: every downstream hash changes.
res = {"app": "h0", "lib": "h0", "util": "h0"}
out = recompute(chain, res, ["util"])
assert out == {"recomputed": ["app", "lib", "util"], "cleaned": []}
# and results is not mutated
assert res == {"app": "h0", "lib": "h0", "util": "h0"}

# Source cutoff: reformatted-but-identical body -> new hash equals stored ->
# cutoff fires at the source, the dependent never recomputes.
src = {"fmt": [], "reader": ["fmt"]}
res = {"fmt": "src:fmt", "reader": "f:reader(fmt=src:fmt)"}
out = recompute(src, res, ["fmt"])
assert out == {"recomputed": [], "cleaned": ["fmt"]}

# Mid-graph cutoff: c changes, m derives the same hash it already stored ->
# m is cleaned and top (dirtied only via m) stays dirty, untouched.
mid = {"c": [], "m": ["c"], "top": ["m"]}
res = {"c": "old", "m": "f:m(c=src:c)", "top": "h0"}
out = recompute(mid, res, ["c"])
assert out == {"recomputed": ["c"], "cleaned": ["m"]}

# Diamond demand: core change recomputes both arms and the root once.
res = {"app": "h0", "lib": "h0", "util": "h0", "core": "h0"}
out = recompute(dia, res, ["core"])
assert out == {"recomputed": ["app", "core", "lib", "util"], "cleaned": []}

# Missing stored hashes read as empty strings (deterministic, never stale).
sparse = {"a": ["b"], "b": [], "c": []}
out = recompute(sparse, {}, ["a"])
assert out == {"recomputed": ["a"], "cleaned": []}

# Duplicate changed entries settle once.
res = {"app": "h0", "lib": "h0", "util": "h0"}
out = recompute(chain, res, ["util", "util"])
assert out == {"recomputed": ["app", "lib", "util"], "cleaned": []}

# No change: nothing recomputes, nothing cleans.
res = {"app": "h0", "lib": "h0", "util": "h0"}
out = recompute(chain, res, [])
assert out == {"recomputed": [], "cleaned": []}

# Unqueried demand: a dirty pack below a cutoff keeps its old hash (test the
# observable: calling recompute twice is pure, same answer both times).
mid = {"c": [], "m": ["c"], "top": ["m"]}
res = {"c": "old", "m": "f:m(c=src:c)", "top": "h0"}
first = recompute(mid, res, ["c"])
second = recompute(mid, res, ["c"])
assert first == second == {"recomputed": ["c"], "cleaned": ["m"]}

print("iss_nateschmiedehaus__LiBrainian__93 ref OK")
