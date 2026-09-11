"""Reference harness: exercises every public function of iss_outline__outline__11760."""
from iss_outline__outline__11760 import DocStore

st = DocStore()
st.add_document("home", "Home")
for doc, title in [("guide", "Guide"), ("api", "API Reference"),
                   ("internal", "Internal Notes")]:
    st.add_document(doc, title, parent_id="home")
st.add_document("roadmap", "Roadmap", parent_id="guide")
st.add_document("payroll", "Payroll", parent_id="internal")
st.add_document("rates", "Rate Card", parent_id="payroll")

# Restrict propagates to every descendant (bulk write over subtree).
assert st.restrict_subtree("internal") == ["internal", "payroll", "rates"]
assert st.restrict_subtree("internal") == []          # idempotent
assert st.is_restricted("payroll")                    # inherited downward
assert st.is_restricted("rates")
assert not st.is_restricted("guide")

# Sidebar prunes at the restricted node: descendants never appear.
levels = st.sidebar_view("home")
flat = sorted(d for lvl in levels for d in lvl)
assert flat == ["api", "guide", "home", "roadmap"]
assert all("internal" not in lvl for lvl in levels)
assert st.hidden_documents() == ["internal", "payroll", "rates"]

# Unrestrict also sweeps the whole subtree back on.
assert st.unrestrict_subtree("internal") == ["internal", "payroll", "rates"]
assert st.hidden_documents() == []

# A leaf restriction hides only itself.
assert st.restrict_subtree("rates") == ["rates"]
assert st.is_restricted("payroll") is False
assert st.hidden_documents() == ["rates"]

# Deep nesting still reaches level-3+ descendants.
deep = DocStore()
for i in range(5):
    deep.add_document("d%d" % i, "t%d" % i, parent_id=("d%d" % (i - 1)) if i else None)
assert deep.restrict_subtree("d2") == ["d2", "d3", "d4"]
assert len(deep.sidebar_view("d0")) == 2   # d2 subtree pruned
assert deep.hidden_documents() == ["d2", "d3", "d4"]
# Unrestricting a mid-chain node cannot undo an ancestor's restriction:
# d1 keeps inheritance on while d0 stays open.
deep.restrict_subtree("d0")
deep.unrestrict_subtree("d1")
assert deep.hidden_documents() == ["d0", "d1", "d2", "d3", "d4"]

# Unknown ids raise; corrupt parent cycle does not hang ascent.
try:
    st.restrict_subtree("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
cyc = DocStore()
cyc.parent_of["a"] = "b"
cyc.parent_of["b"] = "a"
cyc.children_of["a"] = ["b"]
cyc.children_of["b"] = ["a"]
cyc.title_of["a"] = cyc.title_of["b"] = "?"
cyc.restricted = set()
assert sorted(cyc._subtree("a")) == ["a", "b"]         # once-only claim guard
assert cyc.sidebar_view("a") == [["a"], ["b"]]
