"""Bidirectional lineage impact analysis over hand-rolled adjacency dicts.

zer0pool/graph-viz#139: the Impact Analysis page resolves every upstream and
downstream asset connected to an anchor job/table, with a per-direction depth
cap. The in-memory core keeps two id-keyed adjacency containers and rebuilds
reachability per request with an explicit stack loop that re-reads the global
containers at every step. Depth caps are the only termination guarantee when
lineage data arrives malformed.
"""


class LineageGraph:
    def __init__(self):
        self.up = {}    # node id -> [upstream node ids] (what feeds it)
        self.down = {}  # node id -> [downstream node ids] (what it feeds)
        self.kind = {}  # node id -> "table" | "job"

    def add_node(self, nid, kind):
        if kind not in ("table", "job"):
            raise ValueError(kind)
        if nid in self.kind:
            raise ValueError("duplicate node")
        self.kind[nid] = kind
        self.up[nid] = []
        self.down[nid] = []

    def add_edge(self, src, dst):
        """Record that ``src`` feeds ``dst``."""
        if src not in self.kind or dst not in self.kind:
            raise KeyError(src if src not in self.kind else dst)
        self.down[src].append(dst)
        self.up[dst].append(src)

    def _closure(self, start, edges, max_depth):
        seen = set()
        found = []
        stack = [(start, 0)]
        while stack:
            cur, depth = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            found.append(cur)
            if max_depth is not None and depth >= max_depth:
                continue
            for nxt in edges[cur]:  # container re-read per expansion
                stack.append((nxt, depth + 1))
        return found

    def impact(self, anchor, direction="downstream", max_depth=None):
        """Sorted asset ids reachable from anchor in the given direction."""
        if anchor not in self.kind:
            raise KeyError(anchor)
        if direction == "upstream":
            hits = self._closure(anchor, self.up, max_depth)
        elif direction == "downstream":
            hits = self._closure(anchor, self.down, max_depth)
        elif direction == "both":
            ups = set(self._closure(anchor, self.up, max_depth))
            downs = set(self._closure(anchor, self.down, max_depth))
            hits = sorted(ups | downs)
        else:
            raise ValueError(direction)
        return sorted(hits)

    def impact_by_kind(self, anchor, direction="downstream", max_depth=None):
        grouped = {"table": [], "job": []}
        for nid in self.impact(anchor, direction, max_depth):
            grouped[self.kind[nid]].append(nid)
        return grouped

    def max_fanout(self, anchor, max_depth=None):
        """Widest single join: max direct-feeds count over the closure."""
        widest = 0
        for nid in self.impact(anchor, "downstream", max_depth):
            widest = max(widest, len(self.down[nid]))
        return widest
