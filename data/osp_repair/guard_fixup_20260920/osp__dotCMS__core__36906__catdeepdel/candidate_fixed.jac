"""Category tree deletion: recursion depth, cross-listing and orphans.

dotCMS/core#36906 lifted to OSP: categories become CategoryNode
archetypes with typed ChildCategory edges; the contentlet join table
becomes CategorizedIn edges walked in both directions. The deep delete is
two-phase: a level-partitioned hop walk gathers the descendant closure
(depth is part of the defect report) with a shared once-only claim map,
then the facade applies disconnect + unregister outside the walks and
severs only doomed join links, so cross-listed contentlets keep their
outside categories. Sibling order stays observable via sort_order.
"""
node CategoryNode {
    has name: str;
    has sort_order: int = 0;
}
node Contentlet { has cid: str; }

edge ChildCategory {}
edge CategorizedIn {}

"""Tree handle: id resolution through this lookup map is domain API."""
obj Catalog {
    has cats: dict[str, CategoryNode];
    has removed_audit: list[str] = [];

    def resolve(name: str) -> CategoryNode | None {
        return self.cats.get(name);
    }
}

def build_catalog(roots: list[str], links: list[tuple[str, str]]) -> Catalog {
    c = Catalog(cats={});
    for n in roots {
        cn = CategoryNode(name=n);
        root ++> cn;
        c.cats[n] = cn;
    }
    for lk in links {
        p = c.resolve(lk[0]);
        ch = c.resolve(lk[1]);
        if p is not None and ch is not None {
            p +>:ChildCategory:+> ch;
        }
    }
    return c;
}

def add_category(cat: Catalog, name: str, parent: str | None = None, order: int = 0) {
    if parent is not None and cat.resolve(parent) is None {
        raise KeyError("unknown parent category");
    }
    cn = CategoryNode(name=name, sort_order=order);
    root ++> cn;
    cat.cats[name] = cn;
    if parent is not None {
        p = cat.resolve(parent);
        if p is not None {
            p +>:ChildCategory:+> cn;
        }
    }
}

def attach_content(cat: Catalog, contentlet: str, cname: str) -> Contentlet | None {
    target = cat.resolve(cname);
    if target is None {
        raise KeyError("unknown category");
    }
    cu = Contentlet(cid=contentlet);
    root ++> cu;
    cu +>:CategorizedIn:+> target;
    return cu;
}

"""Sibling order is domain-observable (sort_order payload)."""
def children_ordered(cat: Catalog, name: str) -> list[str] {
    start = cat.resolve(name);
    if start is None {
        return [];  # unknown category: empty, like the source's .get default
    }
    kids: list[CategoryNode] = [start ->:ChildCategory:->];
    pairs: list[tuple[int, str]] = [];
    for k in kids {
        pairs.append((k.sort_order, k.name));
    }
    out: list[str] = [];
    for pr in sorted(pairs) {
        out.append(pr[1]);
    }
    return out;
}

"""One-hop child collector with a shared claim map."""
walker HopKids {
    has claimed: dict[str, bool];
    has found: list[CategoryNode] = [];

    can step with CategoryNode entry {
        kids2: list[CategoryNode] = [here ->:ChildCategory:->];
        for k in kids2 {
            if k.name not in self.claimed {
                self.claimed[k.name] = True;
                self.found.append(k);
            }
        }
    }
}

"""Descendant closure grouped by depth; cycle-safe via shared claims."""
def subtree_levels(cat: Catalog, root_cat: str) -> list[list[str]] | None {
    start = cat.resolve(root_cat);
    if start is None {
        return None;
    }
    claimed: dict[str, bool] = {root_cat: True};
    levels: list[list[str]] = [];
    frontier: list[CategoryNode] = [start];
    while len(frontier) > 0 {
        row_names: list[str] = [];
        nxt: list[CategoryNode] = [];
        for f in frontier {
            row_names.append(f.name);
            w = f spawn HopKids(claimed=claimed, found=nxt);
            nxt = w.found;
        }
        levels.append(row_names);
        frontier = nxt;
    }
    return levels;
}

"""Multiset of contentlets touching any node under ``root``."""
def contents_in_subtree(cat: Catalog, root_cat: str) -> list[str] | None {
    levels = subtree_levels(cat, root_cat);
    if levels is None {
        return None;
    }
    hits: list[str] = [];
    for level in levels {
        for cname in level {
            nd = cat.resolve(cname);
            if nd is None {
                continue;
            }
            links: list[Contentlet] = [nd <-:CategorizedIn:<-];
            for cu in links {
                if cu.cid not in hits {
                    hits.append(cu.cid);
                }
            }
        }
    }
    return sorted(hits);
}

"""THE FIX: remove the ENTIRE descendant closure (two-phase).

Returns (total_removed, per_level_counts). Contentlets survive with
their outside links; only doomed join edges are severed.
"""
def delete_category_deep(cat: Catalog, root_cat: str) -> tuple[int, list[int]] {
    start = cat.resolve(root_cat);
    if start is None {
        raise KeyError("unknown category");
    }
    # Phase 1: collect levels and affected contentlets.
    levels = subtree_levels(cat, root_cat);
    affected = contents_in_subtree(cat, root_cat);
    # Phase 2: apply outside the walks.
    parents: list[CategoryNode] = [start <-:ChildCategory:<-];
    if len(parents) > 0 {
        par = parents[0];
        par del ->:ChildCategory:-> start;
    }
    doomed: list[str] = [];
    per_level: list[int] = [];
    for level in levels {
        per_level.append(len(level));
        for cname in level {
            nd = cat.resolve(cname);
            if nd is None {
                continue;
            }
            cus: list[Contentlet] = [nd <-:CategorizedIn:<-];
            for cu in cus {
                cu del ->:CategorizedIn:-> nd;
            }
            doomed.append(cname);
        }
    }
    for cname in doomed {
        cat.cats.pop(cname, None);
    }
    # audit log of deletions is domain behavior and survives
    for cname in doomed {
        cat.removed_audit.append(cname);
    }
    return (len(doomed), per_level);  # tuple like the source
}

"""Invariant checker: every live child's parent is itself live."""
def orphaned_categories(cat: Catalog) -> list[str] {
    out: list[str] = [];
    keys: list[str] = [];
    for k in cat.cats.keys() {
        keys.append(k);
    }
    for k in sorted(keys) {
        nd = cat.resolve(k);
        if nd is None {
            continue;
        }
        parents: list[CategoryNode] = [nd <-:ChildCategory:<-];
        if len(parents) > 0 {
            par = parents[0];
            if par.name not in cat.cats.keys() {
                out.append(k);
            }
        }
    }
    return out;
}
