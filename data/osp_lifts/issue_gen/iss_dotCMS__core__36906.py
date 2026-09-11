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


class CategoryTree:
    def __init__(self):
        self.parent_of = {}      # cat -> parent | None
        self.children_of = {}    # cat -> [child names]
        self.sort_order = {}     # cat -> int position among siblings
        self.content_of = {}     # contentlet -> set of categorized cats
        self.removed = []        # audit log of deletions

    def add_category(self, name, parent=None, order=0):
        if parent is not None and parent not in self.parent_of:
            raise KeyError("unknown parent category")
        self.parent_of[name] = parent
        if parent is not None:
            self.children_of.setdefault(parent, []).append(name)
        self.children_of.setdefault(name, [])
        self.sort_order[name] = order

    def attach_content(self, contentlet, cat):
        """Cross-listing: one contentlet, many categories."""
        if cat not in self.parent_of:
            raise KeyError("unknown category")
        self.content_of.setdefault(contentlet, set()).add(cat)

    def _subtree_levels(self, root):
        """BFS by level; level boundaries are semantically observable.

        The defect report groups lost nodes by depth, so the walk keeps
        frontier lists instead of one flat stack.
        """
        levels = [[root]]
        seen = {root}
        frontier = [root]
        while frontier:
            nxt = []
            for cur in frontier:
                for ch in self.children_of.get(cur, []):
                    if ch not in seen:
                        seen.add(ch)
                        nxt.append(ch)
            if nxt:
                levels.append(nxt)
            frontier = nxt
        return levels

    def children_ordered(self, cat):
        """Sibling order is domain-observable (sort_order)."""
        kids = [c for c in self.children_of.get(cat, []) if c in self.parent_of]
        return sorted(kids, key=lambda c: self.sort_order[c])

    def contents_in_subtree(self, root):
        """Multiset of contentlets touching any node under ``root``."""
        cats = set()
        for level in self._subtree_levels(root):
            cats.update(level)
        hits = set()
        for contentlet, cats_of in self.content_of.items():
            if cats_of & cats:
                hits.add(contentlet)
        return sorted(hits)

    def delete_category_deep(self, root):
        """The fix: remove the ENTIRE descendant closure.

        Two-phase: collect levels + affected contentlets first, apply
        removal afterwards. Returns (total_removed, per-level counts).
        Contentlets are never deleted -- only their links to removed
        categories disappear, so no orphaned references survive.
        """
        if root not in self.parent_of:
            raise KeyError("unknown category")
        levels = self._subtree_levels(root)
        doomed = [c for level in levels for c in level]
        affected = self.contents_in_subtree(root)
        # Phase 2: apply outside collection.
        parent = self.parent_of.get(root)
        if parent is not None:
            self.children_of[parent] = [
                c for c in self.children_of.get(parent, []) if c != root
            ]
        for c in doomed:
            self.children_of.pop(c, None)
            self.parent_of.pop(c, None)
            self.sort_order.pop(c, None)
        for contentlet in affected:
            self.content_of[contentlet] -= set(doomed)
        per_level = [len(level) for level in levels]
        self.removed.extend(doomed)
        return len(doomed), per_level

    def orphaned_categories(self):
        """Invariant checker: every live child has a live parent link."""
        return sorted(
            c for c in self.parent_of
            if self.parent_of[c] is not None
            and self.parent_of[c] not in self.parent_of
        )
