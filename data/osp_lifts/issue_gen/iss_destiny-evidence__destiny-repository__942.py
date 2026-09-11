"""Evidence-map concept taxonomy: subtree rollup counting and filtering.

Before-code synthesized from destiny-evidence/destiny-repository#942: the
search index stores only the concepts a reference was coded to, and nothing
about how they relate, so a parent concept's count covers references coded
at exactly that level while references coded only to descendants are
missed. Rollup mode treats a concept as standing for its whole subtree: a
parent's count includes references coded to any descendant without double
counting (a reference coded to both parent and child counts once), and
filtering on the parent returns exactly the references the count claimed.
Exact-concept behavior is unchanged when rollup is not requested. Parent
pointers, a coded-membership map, and hand-rolled descendant walks below.
"""


class ConceptIndex:
    def __init__(self):
        self.parent_of = {}   # uri -> parent uri | None
        self.coded = {}       # reference -> set of coded concept uris

    def add_concept(self, uri, parent=None):
        if parent is not None and parent not in self.parent_of:
            raise KeyError("unknown parent concept")
        self.parent_of[uri] = parent

    def code(self, reference, uri):
        if uri not in self.parent_of:
            raise KeyError("unknown concept")
        self.coded.setdefault(reference, set()).add(uri)

    def _descendants(self, uri):
        """Everything beneath ``uri`` (excluding it), cycle-tolerant."""
        out = set()
        stack = [uri]
        while stack:
            cur = stack.pop()
            for child, parent in self.parent_of.items():
                if parent == cur and child not in out:
                    out.add(child)
                    stack.append(child)
        return out

    def count(self, uri, rollup=False):
        if uri not in self.parent_of:
            raise KeyError("unknown concept")
        if not rollup:
            return sum(1 for ref in self.coded if uri in self.coded[ref])
        family = self._descendants(uri) | {uri}
        return sum(1 for ref in self.coded if self.coded[ref] & family)

    def filter_refs(self, uri, rollup=False):
        """Sorted references counted by ``count`` -- the same set, exactly."""
        if uri not in self.parent_of:
            raise KeyError("unknown concept")
        if not rollup:
            hits = [r for r in self.coded if uri in self.coded[r]]
        else:
            family = self._descendants(uri) | {uri}
            hits = [r for r in self.coded if self.coded[r] & family]
        return sorted(hits)
