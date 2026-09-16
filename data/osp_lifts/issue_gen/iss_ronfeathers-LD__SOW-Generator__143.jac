# ronfeathers-LD/SOW-Generator#143
# getFolderStructure: unbounded sequential recursion (N+1 Drive calls).
# Idiomatic OSP lift: single bounded walker with claim-map memo instead of
# serial per-subfolder recursion; parent-name lookups memoized.

node Folder {
    has fid: str;
    has name: str;
}

edge Child {
    has page_token: str = "";
}

# memo of folder-id -> name, replaces the serial files.get per parent
def lookup_name(memo: dict[str, str], fid: str, folders: dict[str, Folder]) -> str {
    if fid in memo { return memo[fid]; }
    if fid in folders {
        memo[fid] = folders[fid].name;
        return memo[fid];
    }
    memo[fid] = "<unknown>";
    return "<unknown>";
}

walker FolderWalk {
    has max_depth: int = 3;
    has max_nodes: int = 1000;
    has seen: dict[str, bool] = {};
    has found: list[tuple[str, int, str]] = [];
    has budget: int = 1000;

    can step with Folder entry {
        # claim-map cycle policy: skip revisits, never disengage on revisit
        if here.fid in self.seen { skip; }
        self.seen[here.fid] = True;
        if self.budget <= 0 { disengage; }
        self.budget = self.budget - 1;
        self.found.append((here.fid, here.name, self.depth));
        kids: list[Folder] = [];
        for ch in [here ->:Child:->][?:Folder] {
            kids.append(ch);
        }
        # depth cap mirrors maxDepth=3 default; bounded fan-out replaces N+1
        if self.depth >= self.max_depth { disengage; }
        if len(kids) == 0 {
            visit [] else { disengage; }
        }
        for kid in kids {
            visit kid;
        }
    }
}

# public API shape matches getFolderStructure(root, maxDepth)
def folder_structure(root_node: Folder, max_depth: int = 3) -> list[tuple[str, int, str]] {
    w = root_node spawn FolderWalk(max_depth=max_depth, seen={});
    return w.found;
}

# public API matching getFolderContents(parentId) parent-name lookup
def folder_contents(fid: str, folders: dict[str, Folder], memo: dict[str, str]) -> tuple[str, list[str]] {
    nm = lookup_name(memo, fid, folders);
    kids: list[str] = [];
    if fid in folders {
        for ch in [folders[fid] ->:Child:->][?:Folder] {
            kids.append(ch.fid);
        }
    }
    kids = sorted(kids);
    return (nm, kids);
}
