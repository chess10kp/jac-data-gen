"""Guard: federicodiaz-dev/ImpactLens#28."""

obj DepGraph { has files: dict[str, FileNode] = {}; }
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

test "linear reverse dependents" {
    g = load_graph(
        ["util.py", "model.py", "service.py", "cli.py"],
        [
            ("service.py", "model.py"),
            ("model.py", "util.py"),
            ("cli.py", "service.py"),
        ],
    );
    assert affected_paths(g, ["util.py"]) == ["cli.py", "model.py", "service.py"];
    assert affected_files(g, ["util.py"], max_depth=1) == [("model.py", 1)];
}

test "cycle does not truncate closure" {
    g = load_graph(
        ["a.py", "b.py", "c.py", "d.py"],
        [
            ("a.py", "b.py"),
            ("b.py", "c.py"),
            ("c.py", "a.py"),
            ("c.py", "d.py"),
        ],
    );
    assert affected_paths(g, ["b.py"]) == ["a.py", "c.py"];
}

test "diamond adversarial revisit order" {
    g = load_graph(
        ["core.py", "left.py", "right.py", "app.py"],
        [
            ("left.py", "core.py"),
            ("right.py", "core.py"),
            ("app.py", "left.py"),
            ("app.py", "right.py"),
        ],
    );
    assert affected_paths(g, ["core.py"]) == ["app.py", "left.py", "right.py"];
}

test "multi seed dedupe" {
    g = load_graph(
        ["x.py", "y.py", "z.py"],
        [("y.py", "x.py"), ("z.py", "x.py")],
    );
    assert affected_paths(g, ["x.py", "y.py"]) == ["z.py"];
}

test "unknown seed and zero depth" {
    g = load_graph(
        ["util.py", "model.py"],
        [("model.py", "util.py")],
    );
    assert affected_paths(g, ["missing.py"]) == [];
    assert affected_paths(g, ["util.py"], max_depth=0) == [];
}
