"""federicodiaz-dev/ImpactLens#28 — reverse dependency reachability for affected files."""

obj DepGraph {
    has files: dict[str, FileNode] = {};
}

node FileNode { has path: str; }
edge DependsOn {}

walker DependentHop {
    has claimed: dict[str, bool];
    has next_frontier: list[FileNode] = [];
    has next_depth: int = 0;

    can step with FileNode entry {
        for dep in [here <-:DependsOn:<-][?:FileNode] {
            if dep.path in self.claimed { continue; }
            self.claimed[dep.path] = True;
            self.next_frontier.append(dep);
        }
    }
}

def load_graph(
    files: list[str],
    depends_on: list[tuple[str, str]],
) -> DepGraph {
    g = DepGraph(files={});
    for f in files {
        n = FileNode(path=f);
        root ++> n;
        g.files[f] = n;
    }
    for (importer, imported) in depends_on {
        a = g.files.get(importer, None);
        b = g.files.get(imported, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return g;
}

def _walk_dependents(
    g: DepGraph,
    seeds: list[str],
    max_depth: int | None,
) -> dict[str, int] {
    depths: dict[str, int] = {};
    claimed: dict[str, bool] = {};
    frontier: list[FileNode] = [];
    for s in seeds {
        anchor = g.files.get(s, None);
        if anchor is None { continue; }
        frontier.append(anchor);
        depths[s] = 0;
        claimed[s] = True;
    }
    depth = 0;
    while len(frontier) > 0 {
        if max_depth is not None and depth >= max_depth { break; }
        nxt: list[FileNode] = [];
        for f in frontier {
            w = f spawn DependentHop(claimed=claimed, next_frontier=nxt, next_depth=depth + 1);
            nxt = w.next_frontier;
        }
        for n in nxt { depths[n.path] = depth + 1; }
        depth += 1;
        frontier = nxt;
    }
    return depths;
}

def affected_files(
    g: DepGraph,
    changed: list[str],
    max_depth: int | None = None,
) -> list[tuple[str, int]] {
    changed_set: dict[str, bool] = {};
    for c in changed { changed_set[c] = True; }
    depths = _walk_dependents(g, changed, max_depth);
    out: list[tuple[str, int]] = [];
    for (f, d) in depths.items() {
        if f not in changed_set { out.append((f, d)); }
    }
    return sorted(out);
}

def affected_paths(
    g: DepGraph,
    changed: list[str],
    max_depth: int | None = None,
) -> list[str] {
    rows = affected_files(g, changed, max_depth);
    names: list[str] = [];
    for (f, _) in rows { names.append(f); }
    return sorted(names);
}
