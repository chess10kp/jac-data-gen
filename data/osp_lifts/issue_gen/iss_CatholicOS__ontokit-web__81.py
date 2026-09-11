"""Ontology subgraph builder: bounded BFS with truncation reporting.

CatholicOS/ontokit-web#81: the entity-graph endpoint builds a bounded
subgraph around a focus concept -- ancestors up to a depth, descendants up
to a depth, optional lateral seeAlso links, all under a max-node budget
with an explicit truncation flag. The in-memory core keeps id-keyed concept
and edge tables and re-scans them per hop to find neighbours, so each BFS
level costs a full-table pass. Depth limits and the node budget are
observable API semantics and must survive any rewrite.
"""


class OntologyGraph:
    def __init__(self):
        self.label = {}  # iri -> label
        self.edges = []  # (src_iri, dst_iri, etype) etype: subClassOf|seeAlso

    def add_concept(self, iri, label=""):
        if iri in self.label:
            raise ValueError("duplicate concept")
        self.label[iri] = label

    def add_edge(self, src, dst, etype="subClassOf"):
        for i in (src, dst):
            if i not in self.label:
                raise KeyError(i)
        if etype not in ("subClassOf", "seeAlso"):
            raise ValueError(etype)
        self.edges.append((src, dst, etype))

    def _parents(self, iri):
        return [s for s, d, t in self.edges if d == iri and t == "subClassOf"]

    def _children(self, iri):
        return [d for s, d, t in self.edges if s == iri and t == "subClassOf"]

    def _see_also(self, iri):
        out = []
        for s, d, t in self.edges:
            if t != "seeAlso":
                continue
            if s == iri:
                out.append(d)
            if d == iri:
                out.append(s)
        return out

    def _walk(self, seeds, depth_limit, stepper, budget, visited):
        """BFS frontier loop; returns (visited, hit_budget)."""
        frontier = list(seeds)
        depth = 0
        truncated = False
        while frontier and depth < depth_limit:
            nxt = []
            for cur in frontier:
                for cand in stepper(cur):  # full-table rescan per hop
                    if cand not in visited:
                        if len(visited) >= budget:
                            return visited, True
                        visited.add(cand)
                        nxt.append(cand)
            frontier = nxt
            depth += 1
        return visited, truncated


    def build_subgraph(self, focus, ancestors_depth=2, descendants_depth=2,
                       max_nodes=200, include_see_also=True):
        """Bounded neighbourhood of focus; nodes/edges sorted, flag set
        when the node budget cut the walk short."""
        if focus not in self.label:
            raise KeyError(focus)
        budget = max_nodes
        nodes = {focus}
        _, tr_up = self._walk([focus], ancestors_depth, self._parents, budget, nodes)
        _, tr_down = self._walk(
            [focus], descendants_depth, self._children, budget, nodes
        )
        tr_lat = False
        if include_see_also:
            _, tr_lat = self._walk(nodes, 1, self._see_also, budget, nodes)
        edge_set = set()
        for s, d, t in self.edges:  # whole-edge rescan for induced subgraph
            if s in nodes and d in nodes:
                edge_set.add((s, d, t))
        return {
            "nodes": sorted(nodes),
            "edges": sorted(edge_set),
            "truncated": tr_up or tr_down or tr_lat,
        }
