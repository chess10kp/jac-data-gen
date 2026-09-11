"""CMS content-category registry with cascading category removal.

Categories live in an id-keyed registry; each category knows its parent_id
and may additionally be cross-listed under other categories via
``extra_parents`` (a curated "also appears in" feature), so the ancestry
graph can form diamonds. ``remove_category`` walks the whole descendant
closure -- a shared category is visited twice but MUST be deleted exactly
once -- pops every collected id from the registry, and tolerates entries
whose parent_id went stale (they keep serving as anonymous roots).
"""
class Category {
    has cat_id: str;
    has title: str;
    has parent_id: str | None = None;
    has extra_parents: list[str] = [];
    has article_count: int = 0;
    def init(self: Category, cat_id: str, title: str) -> object {
        self.cat_id = cat_id;
        self.title = title;
        self.parent_id = None;
        self.extra_parents = [];
        self.article_count = 0;
    }
}
class CmsCatalog {
    has categories: dict[str, Category];
    def init(self: CmsCatalog) -> object {
        self.categories = {};
    }
    def add(
        self: CmsCatalog, cat_id: str, title: str, parent_id: str | None = None
    ) -> object {
        cat = Category(cat_id, title);
        cat.parent_id = parent_id;
        self.categories[cat_id] = cat;
        return cat;
    }
    def cross_list(self: CmsCatalog, cat_id: str, extra_parent_id: str) -> object {
        self.categories[cat_id].extra_parents.append(extra_parent_id);
    }
    def _collect_descendants(
        self: CmsCatalog, cat_id: str, visited: set[str], doomed: list[str]
    ) -> object {
        if ((cat_id in visited) or (cat_id not in self.categories)) {
            return;
        }
        visited.add(cat_id);
        doomed.append(cat_id);
        for child in self.categories.values() {
            if (child.parent_id == cat_id) {
                self._collect_descendants(child.cat_id, visited, doomed);
            } elif (cat_id in child.extra_parents) {
                self._collect_descendants(child.cat_id, visited, doomed);
            }
        }
    }

    def remove_category(self: CmsCatalog, cat_id: str) -> object {
        if (cat_id not in self.categories) {
            return [];
        }
        doomed = [];
        self._collect_descendants(cat_id, set(), doomed);
        for dead in doomed {
            delete(self.categories[dead],);
        }
        return sorted(doomed);
    }

    def children_of(self: CmsCatalog, cat_id: Any) -> object {
        if ((cat_id != "__root__") and (cat_id not in self.categories)) {
            return [];
        }
        return sorted(
            c.cat_id
            for c in self.categories.values()
            if (c.parent_id == cat_id)
        );
    }
    def titles(self: CmsCatalog) -> object {
        return sorted(c.title for c in self.categories.values());
    }
}

