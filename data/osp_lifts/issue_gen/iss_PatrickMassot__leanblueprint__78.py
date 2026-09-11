"""Dependency-graph ancestors with explicit cycle detection.

Before-code synthesized from PatrickMassot/leanblueprint#78: a plasTeX
depgraph keeps ``_predecessors``/``_successors`` maps and computes
``ancestors(node)`` as a recursive set union -- a circular ``\\uses``
dependency sends it into unbounded recursion (RecursionError). The fix
requested: short-circuit cycles and NAME the labels that caused them. Here
``ancestors`` walks with an explicit path stack and raises ``CycleError``
carrying the offending cycle; ``find_cycle`` scans the whole graph. Plain
depth-first machinery throughout: dict adjacency, recursion, visited set.
"""


class CycleError(ValueError):
    def __init__(self, cycle):
        super().__init__("dependency cycle: " + " -> ".join(cycle))
        self.cycle = list(cycle)


class DepGraph:
    def __init__(self):
        self._pred = {}  # label -> labels this one uses
        self._succ = {}  # label -> labels that use this one

    def add_node(self, label):
        self._pred.setdefault(label, [])
        self._succ.setdefault(label, [])

    def add_edge(self, user, used):
        # user depends on used
        if user not in self._pred or used not in self._pred:
            raise KeyError("unknown label")
        self._pred[user].append(used)
        self._succ[used].append(user)

    def predecessors(self, label):
        """Labels this label directly uses."""
        if label not in self._pred:
            raise KeyError("unknown label")
        return list(self._pred[label])

    def successors(self, label):
        """Labels that directly use this label."""
        if label not in self._succ:
            raise KeyError("unknown label")
        return list(self._succ[label])

    def ancestors(self, label):
        """Transitive closure over predecessors; raises on any cycle
        reachable from label."""
        if label not in self._pred:
            raise KeyError("unknown label")
        out = set()
        path = []

        def visit(cur):
            for nxt in self._pred[cur]:
                if nxt in path:
                    cycle = path[path.index(nxt):] + [nxt]
                    raise CycleError(cycle)
                if nxt in out:
                    continue
                out.add(nxt)
                path.append(nxt)
                visit(nxt)
                path.pop()

        visit(label)
        return out

    def find_cycle(self):
        """First cycle anywhere in the graph, or empty list."""
        for start in self._pred:
            seen = set()
            path = []

            def visit(cur):
                for nxt in self._pred[cur]:
                    if nxt in path:
                        return path[path.index(nxt):] + [nxt]
                    if nxt in seen:
                        continue
                    seen.add(nxt)
                    path.append(nxt)
                    found = visit(nxt)
                    path.pop()
                    if found:
                        return found
                return None

            found = visit(start)
            if found:
                return found
        return []
