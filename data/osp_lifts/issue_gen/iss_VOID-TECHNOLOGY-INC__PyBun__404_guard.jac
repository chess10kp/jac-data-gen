node Directory {
    has path: str;
    has module: bool = False;
}

edge Contains {}

walker DirectoryScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Directory entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        print("scanned " + here.path);
        if here.module {
            self.found.append(here.path);
        }
        for kid in [here ->:Contains:->][?:Directory] {
            visit :0: [kid];
        }
    }
}

def scan_directory(
    root_id: str,
    directories: list[tuple[str, str]],
    module_ids: list[str],
) -> list[str] {
    nodes: dict[str, Directory] = {};

    nodes[root_id] = Directory(path=root_id);
    for pair in directories {
        source_id: str = pair[0];
        target_id: str = pair[1];
        if source_id not in nodes {
            nodes[source_id] = Directory(path=source_id);
        }
        if target_id not in nodes {
            nodes[target_id] = Directory(path=target_id);
        }
    }

    for module_id in module_ids {
        if module_id in nodes {
            nodes[module_id].module = True;
        }
    }

    for pair in directories {
        source_id: str = pair[0];
        target_id: str = pair[1];
        if source_id in nodes and target_id in nodes {
            nodes[source_id] +>:Contains:+> nodes[target_id];
        }
    }

    if root_id not in nodes {
        return [];
    }
    root_node: Directory = nodes[root_id];
    scan = root_node spawn DirectoryScan(claimed={});
    return sorted(scan.found);
}

test "self cycle terminates and keeps module" {
    assert (
        scan_directory(
            "pkg",
            [("pkg", "loop"), ("loop", "pkg")],
            ["pkg"],
        )
        == ["pkg"]
    );
}

test "parent cycle terminates" {
    assert (
        scan_directory(
            "a",
            [("a", "b"), ("b", "back"), ("back", "a")],
            ["a", "b"],
        )
        == ["a", "b"]
    );
}

test "diamond revisit preserves both descendants" {
    assert (
        scan_directory(
            "root",
            [
                ("root", "left"),
                ("root", "right"),
                ("left", "shared"),
                ("right", "shared"),
                ("shared", "leaf"),
            ],
            ["left", "shared", "leaf"],
        )
        == ["leaf", "left", "shared"]
    );
}

test "unknown root is tolerated" {
    assert (scan_directory("missing", [("a", "b")], ["a"]) == []);
}

test "unknown module id is ignored" {
    assert (
        scan_directory("root", [("root", "pkg")], ["pkg", "missing"])
        == ["pkg"]
    );
}
