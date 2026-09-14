node Directory {
    has id: str;
    has name: str;
    has relative_path: str;
    has is_directory: bool = True;
    has reparse: bool = False;
}

edge Contains {}

walker InventoryWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has recurse: bool = True;

    can step with Directory entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        self.found.append(here.relative_path);
        print(here.relative_path);
        if self.recurse and here.is_directory and not here.reparse {
            for kid in [here ->:Contains:->][?:Directory] {
                visit :0: [kid];
            }
        }
    }
}

walker FindWalker {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    has recurse: bool = True;

    can search with Directory entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print(here.relative_path);
        if here.id == self.target_id {
            self.found = True;
        }
        if self.recurse and here.is_directory and not here.reparse {
            for kid in [here ->:Contains:->][?:Directory] {
                visit :0: [kid];
            }
        }
    }
}

def collect_paths(root_node: Directory, recurse: bool = True) -> list[str] {
    w = root_node spawn InventoryWalker(claimed={}, found=[], recurse=recurse);
    return sorted(w.found);
}

def find_entry(root_node: Directory, target_id: str, recurse: bool = True) -> bool {
    w = root_node spawn FindWalker(target_id=target_id, claimed={}, found=False, recurse=recurse);
    return w.found;
}

def compare_directories(left_root: Directory, right_root: Directory, recurse: bool = True) -> dict[str, list[str]] {
    left_paths: list[str] = collect_paths(left_root, recurse);
    right_paths: list[str] = collect_paths(right_root, recurse);
    result: dict[str, list[str]] = {
        "left_only": [],
        "right_only": [],
        "shared": []
    };
    for path in left_paths {
        if path in right_paths {
            result["shared"].append(path);
        } else {
            result["left_only"].append(path);
        }
    }
    for path in right_paths {
        if path not in left_paths {
            result["right_only"].append(path);
        }
    }
    result["left_only"] = sorted(result["left_only"]);
    result["right_only"] = sorted(result["right_only"]);
    result["shared"] = sorted(result["shared"]);
    return result;
}

test "diamond revisit preserves closure" {
    root_node = Directory(id="root", name="root", relative_path=".");
    left = Directory(id="left", name="left", relative_path="left");
    right = Directory(id="right", name="right", relative_path="right");
    shared = Directory(id="shared", name="shared", relative_path="shared");
    leaf = Directory(id="leaf", name="leaf", relative_path="shared/leaf");
    tail = Directory(id="tail", name="tail", relative_path="right/tail");
    root_node +>:Contains:+> left;
    root_node +>:Contains:+> right;
    left +>:Contains:+> shared;
    right +>:Contains:+> shared;
    shared +>:Contains:+> leaf;
    right +>:Contains:+> tail;
    assert (collect_paths(root_node) == [".", "left", "right", "right/tail", "shared", "shared/leaf"]);
    assert (find_entry(root_node, "leaf"));
}

test "reparse point is surfaced but not traversed" {
    root_node = Directory(id="root", name="root", relative_path=".");
    link = Directory(id="link", name="link", relative_path="external-link", reparse=True);
    outside = Directory(id="outside", name="outside.txt", relative_path="external-link/outside.txt", is_directory=False);
    root_node +>:Contains:+> link;
    link +>:Contains:+> outside;
    assert (collect_paths(root_node) == [".", "external-link"]);
    assert (find_entry(root_node, "outside") == False);
}

test "unknown ids and nonrecursive mode are safe" {
    root_node = Directory(id="root", name="root", relative_path=".");
    child = Directory(id="child", name="child", relative_path="child");
    root_node +>:Contains:+> child;
    assert (find_entry(root_node, "missing") == False);
    assert (collect_paths(root_node, False) == ["."]);
}

test "comparison reports shared and one-sided entries" {
    left_root = Directory(id="left-root", name="root", relative_path=".");
    right_root = Directory(id="right-root", name="root", relative_path=".");
    same_left = Directory(id="same-left", name="same", relative_path="same");
    only_left = Directory(id="only-left", name="left.txt", relative_path="left.txt", is_directory=False);
    same_right = Directory(id="same-right", name="same", relative_path="same");
    only_right = Directory(id="only-right", name="right.txt", relative_path="right.txt", is_directory=False);
    left_root +>:Contains:+> same_left;
    left_root +>:Contains:+> only_left;
    right_root +>:Contains:+> same_right;
    right_root +>:Contains:+> only_right;
    result = compare_directories(left_root, right_root);
    assert (result["shared"] == [".", "same"]);
    assert (result["left_only"] == ["left.txt"]);
    assert (result["right_only"] == ["right.txt"]);
}
