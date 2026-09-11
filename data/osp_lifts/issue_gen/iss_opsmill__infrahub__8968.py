"""Schema profile hierarchy resolution.

Before-code synthesized from opsmill/infrahub#8968: root resolution
walked ``parent`` pointers with no cycle guard, so a kind whose parent
was itself sent the resolver into infinite recursion. The hand-rolled
ascent here carries an explicit visited-kind set: a self-parent or any
revisited ancestor raises ``SchemaCycleError`` instead of recursing
forever, and lineage queries share the same guard.
"""


class SchemaCycleError(ValueError):
    """The profile hierarchy loops back on itself."""


class SchemaHierarchy:
    def __init__(self):
        self.parent_of = {}   # kind -> parent kind | None

    def register_kind(self, kind, parent_kind=None):
        if parent_kind is not None and parent_kind not in self.parent_of:
            raise KeyError("unknown parent kind")
        # NOTE: a self-parent is accepted at registration time -- exactly
        # the corrupt shape issue #8968 observed on sync/arista.
        self.parent_of[kind] = parent_kind

    def _ascend(self, kind):
        """Walk parents from ``kind``; returns (chain, hit_cycle)."""
        chain = []
        seen = set()
        cur = kind
        while cur is not None:
            if cur in seen:
                return chain, True
            seen.add(cur)
            chain.append(cur)
            cur = self.parent_of.get(cur)
        return chain, False

    def resolve_root(self, kind):
        """The most distant ancestor kind name."""
        chain, hit_cycle = self._ascend(kind)
        if hit_cycle:
            raise SchemaCycleError("hierarchy cycle at %r" % chain[-1])
        return chain[-1]

    def lineage(self, kind):
        """Ancestor kinds nearest-first; raises on cycle."""
        chain, hit_cycle = self._ascend(kind)
        if hit_cycle:
            raise SchemaCycleError("hierarchy cycle at %r" % chain[-1])
        return chain[1:]

    def children_of(self, kind):
        """Sorted direct child kinds of ``kind``."""
        return sorted(k for k, p in self.parent_of.items() if p == kind)
