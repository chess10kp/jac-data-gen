"""Document-tree permission restriction with descendant propagation.

Before-code synthesized from outline/outline#11760: document permissions
cascade downward via parent-child links, and toggling inheritance off must
propagate to ALL descendants (bulk write over the subtree), while the
sidebar prunes the rendered subtree at any restricted node. The store keeps
``parent_id`` pointers plus a children adjacency dict; propagation and
pruning are hand-rolled stack walks over that adjacency map.
"""


class DocStore:
    def __init__(self):
        self.parent_of = {}      # doc_id -> parent doc_id | None
        self.children_of = {}    # doc_id -> [child ids in insertion order]
        self.restricted = set()  # ids with inheritance off
        self.title_of = {}

    def add_document(self, doc_id, title, parent_id=None):
        if parent_id is not None and parent_id not in self.parent_of:
            raise KeyError("unknown parent document")
        self.parent_of[doc_id] = parent_id
        if parent_id is not None:
            self.children_of.setdefault(parent_id, []).append(doc_id)
        self.children_of.setdefault(doc_id, [])
        self.title_of[doc_id] = title

    def _subtree(self, root_id):
        """Explicit stack walk over the children adjacency dict."""
        out = []
        stack = [root_id]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue  # cycle guard on corrupt data
            seen.add(cur)
            out.append(cur)
            for ch in self.children_of.get(cur, []):
                stack.append(ch)
        return out

    def restrict_subtree(self, doc_id):
        """Turn inheritance off for the doc AND every descendant (bulk write)."""
        if doc_id not in self.parent_of:
            raise KeyError("unknown document")
        changed = []
        for d in self._subtree(doc_id):
            if d not in self.restricted:
                self.restricted.add(d)
                changed.append(d)
        return sorted(changed)

    def unrestrict_subtree(self, doc_id):
        """Turn inheritance back on for the doc AND every descendant."""
        if doc_id not in self.parent_of:
            raise KeyError("unknown document")
        changed = []
        for d in self._subtree(doc_id):
            if d in self.restricted:
                self.restricted.discard(d)
                changed.append(d)
        return sorted(changed)

    def _ancestors(self, doc_id):
        chain = []
        seen = {doc_id}
        cur = self.parent_of.get(doc_id)
        while cur is not None:
            if cur in seen:
                break  # tolerate cycles: stop ascending
            seen.add(cur)
            chain.append(cur)
            cur = self.parent_of.get(cur)
        return chain

    def is_restricted(self, doc_id):
        """Restricted means: itself restricted or any ancestor restricted."""
        if doc_id in self.restricted:
            return True
        return any(a in self.restricted for a in self._ancestors(doc_id))

    def sidebar_view(self, root_id):
        """Prune at restricted nodes: returns visible ids level by level.

        A restricted node is hidden entirely, so the walk never emits nor
        descends into one. Levels are semantically observable (sidebar
        nesting depth), returned as list of lists.
        """
        levels = [[root_id]]
        frontier = [root_id]
        seen = {root_id}
        while frontier:
            nxt = []
            for cur in frontier:
                for ch in self.children_of.get(cur, []):
                    if ch in seen:
                        continue
                    seen.add(ch)
                    if ch in self.restricted:
                        continue  # hidden entirely: prune here
                    nxt.append(ch)
            if nxt:
                levels.append(nxt)
            frontier = nxt
        return levels

    def hidden_documents(self):
        return sorted(d for d in self.parent_of if self.is_restricted(d))
