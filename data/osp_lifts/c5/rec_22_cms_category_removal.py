"""CMS content-category registry with cascading category removal.

Categories live in an id-keyed registry; each category knows its parent_id
and may additionally be cross-listed under other categories via
``extra_parents`` (a curated "also appears in" feature), so the ancestry
graph can form diamonds. ``remove_category`` walks the whole descendant
closure -- a shared category is visited twice but MUST be deleted exactly
once -- pops every collected id from the registry, and tolerates entries
whose parent_id went stale (they keep serving as anonymous roots).
"""


class Category:
    def __init__(self, cat_id, title):
        self.cat_id = cat_id
        self.title = title
        self.parent_id = None
        self.extra_parents = []   # curated cross-listing -> diamonds
        self.article_count = 0


class CmsCatalog:
    def __init__(self):
        self.categories = {}      # cat_id -> Category

    def add(self, cat_id, title, parent_id=None):
        cat = Category(cat_id, title)
        cat.parent_id = parent_id
        self.categories[cat_id] = cat
        return cat

    def cross_list(self, cat_id, extra_parent_id):
        self.categories[cat_id].extra_parents.append(extra_parent_id)

    def _collect_descendants(self, cat_id, visited, doomed):
        """Recursive descent over the id graph.

        Once-only guard: a diamond reach adds the id once. Unknown parent
        ids are skipped (dangling references are tolerated).
        """
        if cat_id in visited or cat_id not in self.categories:
            return
        visited.add(cat_id)
        doomed.append(cat_id)
        for child in self.categories.values():
            if child.parent_id == cat_id:
                self._collect_descendants(child.cat_id, visited, doomed)
            elif cat_id in child.extra_parents:
                self._collect_descendants(child.cat_id, visited, doomed)

    def remove_category(self, cat_id):
        """Remove *cat_id* and every descendant; returns removed ids sorted.

        Unknown ids are a silent no-op. Stale parent references left behind
        by other mutations are tolerated, never raised.
        """
        if cat_id not in self.categories:
            return []
        doomed = []
        self._collect_descendants(cat_id, set(), doomed)
        for dead in doomed:
            del self.categories[dead]
        return sorted(doomed)

    def children_of(self, cat_id):
        """Direct children; tolerant of a stale (removed) parent id."""
        if cat_id != "__root__" and cat_id not in self.categories:
            return []
        return sorted(
            c.cat_id for c in self.categories.values()
            if c.parent_id == cat_id
        )

    def titles(self):
        return sorted(c.title for c in self.categories.values())
