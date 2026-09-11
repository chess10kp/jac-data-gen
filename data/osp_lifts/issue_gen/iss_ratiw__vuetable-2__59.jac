"""Component-tree callback lookup, lifted to OSP.

Components become nodes chained by typed ParentOf edges (parent
+>:ParentOf:+> child); the while-loop over ``$parent`` pointers becomes a
single-lineage ancestor walker. The ascent-order chain is caller-observable
(the nearest owner wins), so the walker collects it in visit order and the
facade scans it front-to-back. Dead ends (root, unknown parent) disengage.
Ref: ratiw/vuetable-2#59
"""
node Component {
    has name: str;
    has methods: list[str];
}

"""parent +>:ParentOf:+> child."""
edge ParentOf {}

def load_tree(spec: dict[str, list]) -> dict[str, Component] {
    tree: dict[str, Component] = {};
    for name in spec.keys() {
        c = Component(name=name, methods=list(spec[name][1]));
        root ++> c;
        tree[name] = c;
    }
    for name in spec.keys() {
        parent = spec[name][0];
        if parent is not None {
            p = tree.get(parent);
            # Unknown parent terminates the chain at the last known node.
            if p is not None {
                p +>:ParentOf:+> tree[name];
            }
        }
    }
    return tree;
}

walker Ancestors {
    """Ascent-order chain of component names, self first."""
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Component entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        visit [here <-:ParentOf:<-] else { disengage; }
    }
}

"""Component chain in ascent order ``[name, parent, ...]``."""
def ancestors_of(tree: dict[str, Component], name: str) -> list[str] {
    c = tree.get(name);
    if c is None {
        return [];
    }
    w = c spawn Ancestors();
    return w.chain;
}

"""Nearest component (self first) defining ``func``; None when absent."""
def resolve_owner(tree: dict[str, Component], name: str, func: str) -> str | None {
    for comp in ancestors_of(tree, name) {
        if func in tree[comp].methods {
            return comp;
        }
    }
    return None;
}

"""True when some component on the chain defines ``func``."""
def has_callback(tree: dict[str, Component], name: str, func: str) -> bool {
    return resolve_owner(tree, name, func) is not None;
}

"""Sorted union of methods defined along the chain."""
def visible_methods(tree: dict[str, Component], name: str) -> list[str] {
    seen: set[str] = set();
    for comp in ancestors_of(tree, name) {
        for m in tree[comp].methods {
            seen.add(m);
        }
    }
    return sorted(seen);
}
