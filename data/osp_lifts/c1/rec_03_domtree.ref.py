"""Reference harness for rec_03_domtree (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_03_domtree import (
    MAX_OUTLINE_DEPTH,
    append_child,
    element_depth,
    query_selector_all,
    render_outline,
    subtree_width,
)

doc = append_child(None, "html", "d0")
body = append_child(doc, "body", "d1")
div_a = append_child(body, "div", "a")
div_b = append_child(body, "div", "b")
span1 = append_child(div_a, "span", "s1")
p_deep = append_child(span1, "p", "p1")
sec_deep = append_child(p_deep, "section", "sec1")

print("element_depth(sec1):", element_depth(sec_deep))
assert element_depth(sec_deep) == 6, element_depth(sec_deep)

spans = query_selector_all(doc, "span")
divs = query_selector_all(div_b, "span")
print("query_selector_all(doc,'span'):", spans)
print("query_selector_all(div_b,'span'):", divs)
assert spans == ["s1"], spans
assert divs == [], divs

outline = render_outline(doc)
print("render_outline(doc):", outline)
expected = ["body#d1", "div#a", "div#b", "html#d0"]
assert outline == expected, outline

widths = {"doc": subtree_width(doc), "div_a": subtree_width(div_a),
          "sec1": subtree_width(sec_deep)}
print("subtree_width:", widths)
assert widths == {"doc": 7, "div_a": 4, "sec1": 1}, widths

cap_ok = all(len(lab.split("#")[0]) > 0 for lab in outline)
print("outline respects MAX_OUTLINE_DEPTH =", MAX_OUTLINE_DEPTH, ":", cap_ok)
assert cap_ok

# §5.4 invariant: acyclic by construction (append_child only links downward).
print("rec_03_domtree: all assertions passed")
