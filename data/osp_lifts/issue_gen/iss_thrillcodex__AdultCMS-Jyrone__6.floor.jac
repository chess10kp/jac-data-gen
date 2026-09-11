"""thrillcodex/AdultCMS-Jyrone#6 — Category hierarchy with cascade soft-delete.

Hierarchical categories use parent pointers and children adjacency; deleting
a category cascades to descendants in two phases: collect via stack walk,
then mark removed outside the walk.
"""
import from __future__ { annotations }
class CategoryStore {
    def init(self: CategoryStore) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.children_of: dict[(str, list[str])] = {};
        self.removed: set[str] = `set();
    }
    def add_category(
        self: CategoryStore, slug: str, parent: (str | None) = None
    ) -> None {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent category");
        }
        self.parent_of[slug] = parent;
        self.children_of.setdefault(slug, []);
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(slug);
        }
    }
    def _collect_subtree(self: CategoryStore, root_slug: str) -> list[str] {
        stack = [root_slug];
        seen: set[str] = `set();
        out: list[str] = [];
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            for ch in self.children_of.get(cur, []) {
                stack.append(ch);
            }
        }
        return out;
    }
    def cascade_delete(self: CategoryStore, slug: str) -> list[str] {
        if (slug not in self.parent_of) {
            raise KeyError("unknown category");
        }
        to_remove = self._collect_subtree(slug);
        changed: list[str] = [];
        for sid in to_remove {
            if (sid not in self.removed) {
                self.removed.add(sid);
                changed.append(sid);
            }
        }
        return sorted(changed);
    }
    def active_categories(self: CategoryStore) -> list[str] {
        return sorted(
            s
            for s in self.parent_of
            if (s not in self.removed)
        );
    }
}

