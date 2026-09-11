"""Schema dependency graph with foreign-key impact analysis.

paulushcgcj/sqlfy#76: the impact command resolves, for any selected table or
column, every affected object within a traversal depth and direction
(downstream = what breaks if this changes; upstream = what this depends on).
The in-memory core keeps flat object/edge tables and re-scans the whole edge
table once per traversal step to find dependents, plus a containment lookup
that rescans per column. Depth defaults to 3.
"""
class SchemaGraph {
    def init(self: SchemaGraph) -> object {
        self.objects = {};
        self.refs = [];
    }
    def add_table(self: SchemaGraph, name: Any) -> object {
        if (name in self.objects) {
            raise ValueError("duplicate");
        }
        self.objects[name] = {"kind": "table", "parent": None};
    }
    def add_column(self: SchemaGraph, table: Any, col: Any) -> object {
        if (table not in self.objects) {
            raise KeyError(table);
        }
        full = "{}.{}".format(table, col);
        self.objects[full] = {"kind": "column", "parent": table};
    }
    def add_fk(self: SchemaGraph, dependent: Any, referenced: Any) -> object {
        for t in (dependent, referenced) {
            if (self.objects.get(t, {}).get("kind") != "table") {
                raise KeyError(t);
            }
        }
        self.refs.append((dependent, referenced));
    }
    def _dependents(self: SchemaGraph, table: Any) -> object {
        return [
            d
            for (d, r) in self.refs
            if (r == table)
        ];
    }
    def _references(self: SchemaGraph, table: Any) -> object {
        return [
            r
            for (d, r) in self.refs
            if (d == table)
        ];
    }
    def _walk(self: SchemaGraph, start: Any, max_depth: Any, stepper: Any) -> set {
        seen = {start};
        frontier = [start];
        depth = 0;
        while (frontier and (depth < max_depth)) {
            nxt = [];
            for cur in frontier {
                for cand in stepper(cur) {
                    if (cand not in seen) {
                        seen.add(cand);
                        nxt.append(cand);
                    }
                }
            }
            frontier = nxt;
            depth += 1;
        }
        return seen;
    }
    """Sorted object names affected by changing obj, within depth."""
    def impact(
        self: SchemaGraph, `obj: Any, direction: Any = "downstream", depth: Any = 3
    ) -> object {
        if (`obj not in self.objects) {
            raise KeyError(`obj);
        }
        seed = self.objects[`obj]["parent"] or `obj;
        if (direction == "downstream") {
            hit = self._walk(seed, depth, self._dependents);
        } elif (direction == "upstream") {
            hit = self._walk(seed, depth, self._references);
        } else {
            raise ValueError(direction);
        }
        hit.add(`obj);
        out = `set(hit);
        for (name, meta) in self.objects.items() {
            if (meta["parent"] in hit) {
                out.add(name);
            }
        }
        return sorted(out);
    }
    def counts_by_kind(self: SchemaGraph, names: Any) -> object {
        counts = {"table": 0, "column": 0};
        for n in names {
            counts[self.objects[n]["kind"]] += 1;
        }
        return counts;
    }
}

