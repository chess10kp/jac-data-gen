"""RL driver (pure-lib): social_graph feed search filter.

Origin: this_is_jac/littlex/social_graph.jac (the `load_feed` deliver search
filter: lowercase+strip the query, keep items whose lowercased content contains it,
isolated from the graph walk). Deterministic: pure case-insensitive substring
filter over a fixed list. The marked body is the unit the policy must regenerate;
the `with entry` block exercises it on fixed inputs and prints a deterministic
projection.
"""

def _search_filter(contents: list, query: str) -> list {
    # >>>HOLE id="lib_feed_search" instruction="Implement _search_filter(contents, query): let q be query lowercased and stripped; return the list of items c from contents whose lowercased form contains q as a substring."
    q = query.lower().strip();
    return [c for c in contents if q in c.lower()];
    # <<<HOLE
}

with entry {
    contents = ["Hello Jac", "Graph DB rocks", "jac is fun", "Python here"];
    for q in ["  JAC ", "graph", "xyz", ""] {
        print(str(_search_filter(contents, q)));
    }
}
