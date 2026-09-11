"""Guard: Cacti/cacti#7713."""

obj FileIndex { has paths: dict[str, bool] = {}; }

def load_index(entries: list[tuple[str, bool]]) -> FileIndex {
    idx = FileIndex();
    for (path, is_dir) in entries { idx.paths[path] = is_dir; }
    return idx;
}

def is_ignored(path: str, ignore: set[str]) -> bool {
    for pat in ignore {
        if path == pat or path.startswith(pat + "/") { return True; }
    }
    return False;
}

def _children_of(idx: FileIndex, parent: str) -> list[str] {
    prefix = "" if parent == "" else parent + "/";
    kids: dict[str, bool] = {};
    for (path, _is_dir) in idx.paths.items() {
        if not path.startswith(prefix) { continue; }
        rest = path[len(prefix):];
        if not rest { continue; }
        if "/" in rest {
            first = rest.split("/")[0];
            key = first if parent == "" else prefix + first;
            kids[key] = True;
        } else {
            kids[path] = True;
        }
    }
    out: list[str] = [];
    for k in kids { out.append(k); }
    return sorted(out);
}

def collect_files(idx: FileIndex, root_path: str, ignore: set[str]) -> list[str] {
    if root_path and root_path not in idx.paths {
        has_child = False;
        for (p, _d) in idx.paths.items() {
            if p.startswith(root_path + "/") { has_child = True; }
        }
        if not has_child { return []; }
    }
    hits: list[str] = [];
    stack: list[str] = [root_path];
    claimed: dict[str, bool] = {};
    while stack {
        cur = stack.pop();
        if cur in claimed { continue; }
        claimed[cur] = True;
        is_dir = idx.paths.get(cur, False);
        if cur and not is_dir {
            if not is_ignored(cur, ignore) { hits.append(cur); }
        }
        kids = _children_of(idx, cur);
        for i in range(len(kids) - 1, -1, -1) {
            ch = kids[i];
            if ch not in claimed { stack.append(ch); }
        }
    }
    return sorted(hits);
}

test "collect with ignore" {
    idx = load_index([
        ("", True),
        ("lib", True),
        ("lib/a.php", False),
        ("lib/vendor", True),
        ("lib/vendor/x.php", False),
        ("include", True),
        ("include/b.php", False),
    ]);
    assert is_ignored("lib/vendor/x.php", {"lib/vendor"}) == True;
    assert collect_files(idx, "", set()) == [
        "include/b.php", "lib/a.php", "lib/vendor/x.php"
    ];
    assert collect_files(idx, "", {"lib/vendor"}) == ["include/b.php", "lib/a.php"];
}

test "missing root tolerant" {
    idx = load_index([("solo.txt", False)]);
    assert collect_files(idx, "missing", set()) == [];
}
