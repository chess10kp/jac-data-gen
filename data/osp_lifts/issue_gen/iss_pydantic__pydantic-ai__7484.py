"""Span tree queries with pruned ancestor/descent walks.

Before-code synthesized from pydantic/pydantic-ai#7484: SpanNode keeps a
``parent`` back-reference plus a ``children`` list; ``ancestors()`` and
``descendants()`` are plain recursive walks. Queries evaluate
all_/no_/some_ ancestor/descendant conditions against PRUNED walks: a
``stop_recursing_when`` condition truncates the walk at matching nodes
(excluded, not descended past). The historical defect was that the pruned
walks were cached generators consumed by three separate conditions, so
only the first condition per side saw any nodes; the contract here is the
fixed semantics -- every condition evaluates against a freshly
materialized pruned list. Attribute conditions match ``attrs`` entries.
"""

STOP = "stop_recursing_when"


class SpanNode:
    def __init__(self, name, span_id, attrs=None):
        self.name = name
        self.span_id = span_id
        self.attrs = attrs or {}
        self.parent = None
        self.children = []

    def add_child(self, child):
        child.parent = self
        self.children.append(child)
        return child

    def ancestors(self):
        """Nearest-first list of ancestor nodes."""
        out = []
        cur = self.parent
        while cur is not None:
            out.append(cur)
            cur = cur.parent
        return out

    def descendants(self):
        """Pre-order list over children (duplicates kept for shared nodes)."""
        out = []

        def walk(node):
            for c in node.children:
                out.append(c)
                walk(c)

        walk(self)
        return out

    def _matches_cond(self, cond):
        return all(self.attrs.get(k) == v for k, v in cond.items())

    def _pruned_ancestors(self, stop):
        out = []
        cur = self.parent
        while cur is not None:
            if stop and cur._matches_cond(stop):
                break
            out.append(cur)
            cur = cur.parent
        return out

    def _pruned_descendants(self, stop):
        out = []

        def walk(node):
            for c in node.children:
                if stop and c._matches_cond(stop):
                    continue
                out.append(c)
                walk(c)

        walk(self)
        return out

    def matches(self, query):
        stop = query.get(STOP)
        anc = self._pruned_ancestors(stop)
        desc = self._pruned_descendants(stop)
        for cond in query.get("all_ancestors_have", []):
            if not all(a._matches_cond(cond) for a in anc):
                return False
        for cond in query.get("no_ancestor_has", []):
            if any(a._matches_cond(cond) for a in anc):
                return False
        for cond in query.get("some_ancestor_has", []):
            if not any(a._matches_cond(cond) for a in anc):
                return False
        for cond in query.get("all_descendants_have", []):
            if not all(d._matches_cond(cond) for d in desc):
                return False
        for cond in query.get("no_descendant_has", []):
            if any(d._matches_cond(cond) for d in desc):
                return False
        for cond in query.get("some_descendant_has", []):
            if not any(d._matches_cond(cond) for d in desc):
                return False
        return True
