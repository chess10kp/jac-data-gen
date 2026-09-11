"""GraphContent: adjacency-backed graph report with a DOT formatter.

sixty-north/asyoulikeit#10: a GraphContent report type built via
add_node/add_edge and rendered to Graphviz DOT. The hand-rolled core is the
adjacency bookkeeping plus a renderer that re-scans the full edge list once
per node to find outgoing edges, then dedups shared endpoints. Node/edge
attribute conventions from the issue: external nodes render dashed, jmp
edges render dashed.
"""

ESCAPE = {"\\": "\\\\", '"': '\\"'}


class GraphContent:
    def __init__(self, title="callgraph", directed=True):
        self.title = title
        self.directed = directed
        self.nodes = {}  # nid -> {"name":..., "external": bool}
        self.edges = {}  # (src,dst) -> {"etype": "jsr"|"jmp"}

    def add_node(self, nid, name=None, external=False):
        if nid in self.nodes:
            raise ValueError("duplicate node")
        self.nodes[nid] = {"name": name or nid, "external": external}
        return self

    def add_edge(self, src, dst, etype="jsr"):
        if src not in self.nodes or dst not in self.nodes:
            raise KeyError(src)
        if etype not in ("jsr", "jmp"):
            raise ValueError(etype)
        self.edges[(src, dst)] = {"etype": etype}
        return self

    def _out_edges(self, nid):
        return [e for e in self.edges if e[0] == nid]  # whole-edge rescan

    def successors(self, nid):
        return sorted(e[1] for e in self._out_edges(nid))

    def reachable(self, start):
        seen = set()
        stack = [start]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            stack.extend(self.successors(cur))
        return sorted(seen)

    @staticmethod
    def _q(label):
        out = label
        for ch, rep in ESCAPE.items():
            out = out.replace(ch, rep)
        return '"' + out + '"'

    def to_dot(self):
        lines = ["digraph " + self._q(self.title) + " {"]
        for nid in sorted(self.nodes):
            meta = self.nodes[nid]
            attrs = ["label=" + self._q(meta["name"])]
            if meta["external"]:
                attrs.append("style=dashed")
                attrs.append("color=gray")
            lines.append("  {} [{}];".format(self._q(nid), ", ".join(attrs)))
        for (s, d) in sorted(self.edges):
            attrs = []
            if self.edges[(s, d)]["etype"] == "jmp":
                attrs.append("style=dashed")
            suffix = " [{}]".format(", ".join(attrs)) if attrs else ""
            arrow = "->" if self.directed else "--"
            lines.append("  {} {} {}{};".format(self._q(s), arrow, self._q(d), suffix))
        lines.append("}")
        return "\n".join(lines) + "\n"
