"""Schema dependency graph with foreign-key impact analysis.

paulushcgcj/sqlfy#76: the impact command resolves, for any selected table or
column, every affected object within a traversal depth and direction
(downstream = what breaks if this changes; upstream = what this depends on).
The in-memory core keeps flat object/edge tables and re-scans the whole edge
table once per traversal step to find dependents, plus a containment lookup
that rescans per column. Depth defaults to 3.
"""


class SchemaGraph:
    def __init__(self):
        self.objects = {}  # name -> {"kind": ..., "parent": table or None}
        self.refs = []     # (dependent_table, referenced_table)

    def add_table(self, name):
        if name in self.objects:
            raise ValueError("duplicate")
        self.objects[name] = {"kind": "table", "parent": None}

    def add_column(self, table, col):
        if table not in self.objects:
            raise KeyError(table)
        full = "{}.{}".format(table, col)
        self.objects[full] = {"kind": "column", "parent": table}

    def add_fk(self, dependent, referenced):
        for t in (dependent, referenced):
            if self.objects.get(t, {}).get("kind") != "table":
                raise KeyError(t)
        self.refs.append((dependent, referenced))

    def _dependents(self, table):
        return [d for d, r in self.refs if r == table]  # full-table rescan

    def _references(self, table):
        return [r for d, r in self.refs if d == table]

    def _walk(self, start, max_depth, stepper):
        seen = {start}
        frontier = [start]
        depth = 0
        while frontier and depth < max_depth:
            nxt = []
            for cur in frontier:
                for cand in stepper(cur):
                    if cand not in seen:
                        seen.add(cand)
                        nxt.append(cand)
            frontier = nxt
            depth += 1
        return seen

    def impact(self, obj, direction="downstream", depth=3):
        """Sorted object names affected by changing obj, within depth."""
        if obj not in self.objects:
            raise KeyError(obj)
        seed = self.objects[obj]["parent"] or obj  # column anchors its table
        if direction == "downstream":
            hit = self._walk(seed, depth, self._dependents)
        elif direction == "upstream":
            hit = self._walk(seed, depth, self._references)
        else:
            raise ValueError(direction)
        hit.add(obj)
        out = set(hit)
        for name, meta in self.objects.items():  # containment rescan
            if meta["parent"] in hit:
                out.add(name)
        return sorted(out)

    def counts_by_kind(self, names):
        counts = {"table": 0, "column": 0}
        for n in names:
            counts[self.objects[n]["kind"]] += 1
        return counts
