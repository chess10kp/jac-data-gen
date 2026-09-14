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
