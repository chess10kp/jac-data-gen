"""Reference harness: exercises every public function of iss_bestofjs__bestofjs__485."""
import importlib

mod = importlib.import_module("iss_bestofjs__bestofjs__485")
CycleError = mod.CycleError
TagTaxonomy = mod.TagTaxonomy

tx = TagTaxonomy()
tx.add_tag("react", facet="ecosystem")
tx.add_tag("nextjs", parent="react", facet="ecosystem")
tx.add_tag("remix", parent="react", facet="ecosystem")
tx.add_tag("nodejs-framework", facet="category")
tx.add_tag("test-framework", facet="category")

# Effective membership closes over ancestor chains.
tx.tag_project("p-vercel", "nextjs")
tx.tag_project("p-shopify", "remix")
tx.tag_project("p-both", "nextjs")
tx.tag_project("p-both", "react")          # redundant direct row
tx.tag_project("p-vitest", "test-framework")

assert tx.effective_tags("p-vercel") == ["nextjs", "react"]
assert tx.projects_with("react") == ["p-both", "p-shopify", "p-vercel"]
assert tx.projects_with("nextjs") == ["p-both", "p-vercel"]
assert tx.rollup_count("react") == 3
assert tx.rollup_count("remix") == 1
assert tx.usage["react"] == 1              # only p-both stores it directly

# Redundancy detection: react implied by nextjs on the same project.
assert tx._redundant_for("p-both") == ["react"]

# Cleanup drops exactly the redundant rows, counts stay honest.
dropped = tx.cleanup_project("p-both")
assert dropped == ["react"]
assert tx.usage["react"] == 0
assert tx.effective_tags("p-both") == ["nextjs", "react"]   # still effective!
assert sorted(tx.tags_of["p-both"]) == ["nextjs"]

# Write-time cycle guard: react cannot move under its own child.
try:
    tx.set_parent("react", "nextjs")
    raise SystemExit("expected CycleError")
except CycleError:
    pass
try:
    tx.set_parent("react", "react")
    raise SystemExit("expected self-cycle reject")
except CycleError:
    pass
try:
    tx.set_parent("react", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Legal reparent: remix moves under nextjs (subset of a subset).
changed = tx.set_parent("remix", "nextjs")
assert changed
assert tx.effective_tags("p-shopify") == ["nextjs", "react", "remix"]

# Sweep after reparent finds nothing new here but runs clean.
assert tx.cleanup_after_reparent() == {}

# A project storing the whole chain collapses to just the leaf.
tx2 = TagTaxonomy()
for t in ["react", "nextjs"]:
    tx2.add_tag(t)
tx2.add_tag("nextjs", parent="react")
tx2.add_tag("vercel-ai", parent="nextjs")
tx2.add_tag("react", None)
tx2.tag_project("p1", "react")
tx2.tag_project("p1", "nextjs")
tx2.tag_project("p1", "vercel-ai")
rep = tx2.cleanup_after_reparent()
assert rep == {"p1": ["nextjs", "react"]}
assert tx2.usage["react"] == 0 and tx2.usage["nextjs"] == 0
assert tx2.effective_tags("p1") == ["nextjs", "react", "vercel-ai"]
