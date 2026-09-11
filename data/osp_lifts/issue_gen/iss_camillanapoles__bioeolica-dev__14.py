"""Provenance chain recording and verification.

camillanapoles/bioeolica-dev#14: src/common/provenance.py records DAG edges
between data objects -- (source_id, target_id, transformation, parameters) --
and verifies completeness of an object's lineage. The module keeps an
adjacency map and answers three questions with plain traversals: what is
upstream/downstream of an object (transitive closures), is the chain complete
(every non-source object traces back to at least one root with no dangling
links), and are there cycles. Results are sets and validity flags.
"""


class ProvenanceLedger:
    """In-memory provenance DAG over data object ids."""

    def __init__(self):
        self.edges = {}       # target_id -> [(source_id, transformation, params)]
        self.redges = {}      # source_id -> [target_id]
        self.nodes = set()

    def record(self, source_id, target_id, transformation="copy", parameters=None):
        """Record one provenance edge; both endpoints become known nodes."""
        if source_id == target_id:
            raise ValueError("self-provenance edge")
        self.nodes.add(source_id)
        self.nodes.add(target_id)
        self.edges.setdefault(target_id, []).append(
            (source_id, transformation, parameters or {})
        )
        self.redges.setdefault(source_id, [])
        if target_id not in self.redges[source_id]:
            self.redges[source_id].append(target_id)

    def _closure(self, start_id, links):
        seen = set()
        stack = list(links.get(start_id, []))
        while stack:
            cur = stack.pop()
            entry = cur[0] if isinstance(cur, tuple) else cur
            if entry in seen:
                continue
            seen.add(entry)
            stack.extend(links.get(entry, []))
        return seen

    def get_upstream(self, object_id):
        """All transitive sources of ``object_id`` (sorted, exclusive)."""
        out = []
        for e in self._closure(object_id, self.edges):
            out.append(e)
        return sorted(out)

    def get_downstream(self, object_id):
        """All transitive consumers of ``object_id`` (sorted, exclusive)."""
        raw = set()
        for t in self._closure(object_id, self.redges):
            raw.add(t)
        return sorted(raw)

    def detect_cycles(self):
        """Sorted objects that lie on a provenance cycle (empty when clean)."""
        bad = []
        for node in sorted(self.nodes):
            if node in self._closure(node, self.redges):
                bad.append(node)
        return bad

    def verify_chain(self, object_id):
        """True when ``object_id`` exists and every trace path bottoms out
        at a root (an object recorded as someone's source but never built
        from anything) with no dangling references."""
        if object_id not in self.nodes:
            return False
        if self.detect_cycles():
            return False
        seen = set()
        stack = [object_id]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            parents = self.edges.get(cur, [])
            for (src, _t, _p) in parents:
                if src not in self.nodes:
                    return False
                stack.append(src)
        roots = {n for n in self.nodes
                 if n not in self.edges or not self.edges[n]}
        return bool(roots & seen)
