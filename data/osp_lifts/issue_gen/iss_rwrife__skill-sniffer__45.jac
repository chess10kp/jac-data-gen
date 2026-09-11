"""rwrife/skill-sniffer#45 — Follow bundled refs with depth cap."""

node BundleFile { has path: str; }
edge References {}

obj SkillBundle { has files: dict[str, BundleFile] = {}; }

def load_bundle(
    files: list[str],
    ref_edges: list[tuple[str, str]],
) -> SkillBundle {
    bundle = SkillBundle();
    for path in files {
        nd = BundleFile(path=path);
        root ++> nd;
        bundle.files[path] = nd;
    }
    for (src, dst) in ref_edges {
        a = bundle.files.get(src, None);
        b = bundle.files.get(dst, None);
        if a is not None and b is not None { a +>:References:+> b; }
    }
    return bundle;
}

def follow_refs(
    bundle: SkillBundle,
    start: str,
    max_depth: int,
) -> list[str] {
    if start not in bundle.files { return []; }
    seen: dict[str, bool] = {};
    reached: list[str] = [];
    frontier: list[tuple[str, int]] = [(start, 0)];
    i = 0;
    while i < len(frontier) {
        (path, depth) = frontier[i];
        i += 1;
        if path in seen { continue; }
        if depth > max_depth { continue; }
        nd = bundle.files.get(path, None);
        if nd is None { continue; }
        seen[path] = True;
        reached.append(path);
        if depth >= max_depth { continue; }
        for nxt in [nd ->:References:->][?:BundleFile] {
            if nxt.path not in seen {
                frontier.append((nxt.path, depth + 1));
            }
        }
    }
    return sorted(reached);
}
