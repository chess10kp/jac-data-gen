"""Category tree deletion: recursion depth, cross-listing and orphans.

Before-code synthesized from dotCMS/core#36906: deleting a category only
removed direct children, leaving levels 3..N alive but severed -- they
rendered as unexpected top-level categories because the FK cascade on the
join table destroyed their parent links while their subtrees survived.
The correct operation collects the WHOLE descendant closure first (level
by level, since depth is part of the defect report), accounts for every
contentlet cross-listed into the doomed subtree, and then applies removal.
Categories keep parent pointers plus a children adjacency dict; sibling
order is explicit and observable; the contentlet<->category join is a
many-to-many map walked in both directions.
"""
class CategoryTree {
    def init(self: CategoryTree)  -> Any {
        self.parent_of = {};
        self.children_of = {};
        self.sort_order = {};
        self.content_of = {};
        self.removed = [];
    }
    def add_category(
        self: CategoryTree, name: Any, parent: Any = None, order: Any = 0
    ) {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent category");
        }
        self.parent_of[name] = parent;
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(name);
        }
        self.children_of.setdefault(name, []);
        self.sort_order[name] = order;
    }
    """Cross-listing: one contentlet, many categories."""
    def attach_content(self: CategoryTree, contentlet: Any, cat: Any)  -> Any {
        if (cat not in self.parent_of) {
            raise KeyError("unknown category");
        }
        self.content_of.setdefault(contentlet, `set()).add(cat);
    }
    """BFS by level; level boundaries are semantically observable.

        The defect report groups lost nodes by depth, so the walk keeps
        frontier lists instead of one flat stack.
        """
    def _subtree_levels(self: CategoryTree, `root: Any)  -> Any {
        levels = [[`root]];
        seen = {`root};
        frontier = [`root];
        while frontier {
            nxt = [];
            for cur in frontier {
                for ch in list(self.children_of.get(cur, [])) {
                    if (ch not in seen) {
                        seen.add(ch);
                        nxt.append(ch);
                    }
                }
            }
            if nxt {
                levels.append(nxt);
            }
            frontier = nxt;
        }
        return levels;
    }

    """Sibling order is domain-observable (sort_order)."""
    def children_ordered(self: CategoryTree, cat: Any)  -> Any {
        kids = [
            c
            for c in self.children_of.get(cat, [])
            if (c in self.parent_of)
        ];
        return sorted(kids, key=lambda (c: Any) { self.sort_order[c]; });
    }
    """Multiset of contentlets touching any node under ``root``."""
    def contents_in_subtree(self: CategoryTree, `root: Any)  -> Any {
        cats = `set();
        for level in self._subtree_levels(`root) {
            cats.update(list(level));
        }
        hits = `set();
        for (contentlet, cats_of) in self.content_of.items() {
            if (cats_of & cats) {
                hits.add(contentlet);
            }
        }
        return sorted(hits);
    }
    """The fix: remove the ENTIRE descendant closure.

        Two-phase: collect levels + affected contentlets first, apply
        removal afterwards. Returns (total_removed, per-level counts).
        Contentlets are never deleted -- only their links to removed
        categories disappear, so no orphaned references survive.
        """
    def delete_category_deep(self: CategoryTree, `root: Any)  -> Any {
        if (`root not in self.parent_of) {
            raise KeyError("unknown category");
        }
        levels = self._subtree_levels(`root);
        doomed = [c for level in levels for c in level];
        affected = self.contents_in_subtree(`root);
        parent = self.parent_of.get(`root);
        if (parent is not None) {
            self.children_of[parent] = [
                c
                for c in self.children_of.get(parent, [])
                if (c != `root)
            ];
        }
        for c in doomed {
            self.children_of.pop(c, None);
            self.parent_of.pop(c, None);
            self.sort_order.pop(c, None);
        }
        for contentlet in affected {
            for dv in doomed {
                if dv in self.content_of[contentlet] {
                    self.content_of[contentlet].discard(dv);
                }
            }
        }
        per_level = [len(level) for level in list(levels)];
        self.removed.extend(doomed);
        return (len(doomed), per_level);
    }

    """Invariant checker: every live child has a live parent link."""
    def orphaned_categories(self: CategoryTree)  -> Any {
        return sorted(
            c
            for c in self.parent_of
            if (
                (self.parent_of[c] is not None)
                and (self.parent_of[c] not in self.parent_of)
            )
        );
    }
}

