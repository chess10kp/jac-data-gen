"""Nimblesite/SharpLsp#169: bounded source-file collection across directory links."""

node Directory {
    has cid: str;
    has path: str;
}

node SourceFile {
    has cid: str;
    has path: str;
}

edge Entry {}
edge Junction {}

walker SourceCollector {
    has claimed: dict[str, bool] = {};
    has depth_by_cid: dict[str, int] = {};
    has found: list[str] = [];
    has max_depth: int = 32;

    can collect_directory with Directory entry {
        cid_key: str = here.cid;
        if cid_key in self.claimed {
            skip;
        }

        current_depth: int = 0;
        if cid_key in self.depth_by_cid {
            current_depth = self.depth_by_cid[cid_key];
        } else {
            self.depth_by_cid[cid_key] = 0;
        }

        if current_depth > self.max_depth {
            skip;
        }

        self.claimed[cid_key] = True;

        for file_node in [here ->:Entry:->][?:SourceFile] {
            self.found.append(file_node.path);
            print(file_node.path);
        }

        if current_depth == self.max_depth {
            skip;
        }

        next_dirs: list[Directory] = [];
        next_depth: int = current_depth + 1;

        for child_dir in [here ->:Entry:->][?:Directory] {
            if child_dir.cid not in self.depth_by_cid {
                self.depth_by_cid[child_dir.cid] = next_depth;
            }
            next_dirs.append(child_dir);
        }

        for linked_dir in [here ->:Junction:->][?:Directory] {
            if linked_dir.cid not in self.depth_by_cid {
                self.depth_by_cid[linked_dir.cid] = next_depth;
            }
            next_dirs.append(linked_dir);
        }

        visit :0: [next_dirs];
    }
}

def collect_source_files(
    graph_root: Directory | None = None,
    max_depth: int = 32
) -> list[str] {
    if graph_root is None {
        return [];
    }
    if max_depth < 0 {
        return [];
    }

    w = graph_root spawn SourceCollector(max_depth=max_depth);
    visit :0: [graph_root];
    return w.found;
}

test "diamond revisit is collected once" {
    root_node = Directory(cid="root", path="/workspace");
    right_dir = Directory(cid="right", path="/workspace/right");
    left_dir = Directory(cid="left", path="/workspace/left");
    shared_dir = Directory(cid="shared", path="/workspace/shared");
    shared_file = SourceFile(cid="shared-file", path="/workspace/shared/main.jac");

    root_node +>:Entry:+> right_dir;
    root_node +>:Entry:+> left_dir;
    right_dir +>:Entry:+> shared_dir;
    left_dir +>:Entry:+> shared_dir;
    shared_dir +>:Entry:+> shared_file;

    found: list[str] = collect_source_files(root_node, 8);
    assert (sorted(found) == ["/workspace/shared/main.jac"]);
}

test "junction cycle terminates" {
    root_node = Directory(cid="root", path="/workspace");
    linked_dir = Directory(cid="linked", path="/workspace/linked");
    linked_file = SourceFile(cid="linked-file", path="/workspace/linked/a.jac");

    root_node +>:Junction:+> linked_dir;
    linked_dir +>:Junction:+> root_node;
    linked_dir +>:Entry:+> linked_file;

    found: list[str] = collect_source_files(root_node, 4);
    assert (sorted(found) == ["/workspace/linked/a.jac"]);
}

test "depth cap blocks deeper files" {
    root_node = Directory(cid="root", path="/workspace");
    one_dir = Directory(cid="one", path="/workspace/one");
    two_dir = Directory(cid="two", path="/workspace/one/two");
    deep_file = SourceFile(cid="deep-file", path="/workspace/one/two/deep.jac");

    root_node +>:Entry:+> one_dir;
    one_dir +>:Entry:+> two_dir;
    two_dir +>:Entry:+> deep_file;

    found: list[str] = collect_source_files(root_node, 1);
    assert (found == []);
}

test "unknown and empty roots are tolerated" {
    missing: Directory | None = None;
    empty_dir = Directory(cid="empty", path="/workspace/empty");

    assert (collect_source_files(missing) == []);
    assert (collect_source_files(empty_dir, 0) == []);
    assert (collect_source_files(empty_dir, -1) == []);
}
