# ronfeathers-LD/SOW-Generator#143
# getFolderStructure: unbounded sequential recursion -> idiomatic OSP walk
# with claim-map cycle policy, depth caps, and node caps.

node Folder {
    has fid: str;
    has name: str;
    has depth: int = 0;
}

edge CHILD;

# key helper for deterministic child ordering (avoids lambda typing issues)
def fid_of(f: Folder) -> str {
    return f.fid;
}

obj DriveTree {
    has by_id: dict[str, Folder] = {};
    has claimed: dict[str, bool] = {};
    has max_depth: int = 3;
    has node_cap: int = 1000;
    has call_count: int = 0;
    has order: list[str] = [];

    def add_folder(fid: str, name: str, depth: int) -> Folder | None {
        if fid in self.by_id { return self.by_id[fid]; }
        if len(self.by_id) >= self.node_cap { return None; }
        nd = Folder(fid=fid, name=name, depth=depth);
        self.by_id[fid] = nd;
        return nd;
    }

    def link(parent: Folder, child: Folder) {
        parent +>:CHILD:+> child;
    }

    # counts Drive calls: one list call per folder visit (serial N+1 baseline
    # was nodes * round_trips; OSP visit claims once per node)
    def record_call {
        self.call_count += 1;
    }

    def get_folder_structure(root_id: str) -> list[str] {
        res: list[str] = [];
        if root_id not in self.by_id { return res; }
        start = self.by_id[root_id];
        cur: list[Folder] = [start];
        # iterative bounded-depth DFS with claim-map cycle policy
        while cur {
            nd = cur.pop(0);
            if nd.fid in self.claimed { continue; }
            self.claimed[nd.fid] = True;
            self.record_call();
            self.order.append(nd.name);
            res.append(nd.fid);
            if nd.depth >= self.max_depth { continue; }
            kids: list[Folder] = [];
            for ch in [nd ->:CHILD:->][?:Folder] { kids.append(ch); }
            kids = sorted(kids, key=fid_of);
            for kk in kids { cur.insert(0, kk); }
        }
        res = sorted(res);
        return res;
    }

    # cached parent-name lookup (was an extra serial files.get per call)
    def get_folder_name(fid: str) -> str | None {
        if fid not in self.by_id { return None; }
        return self.by_id[fid].name;
    }
}

walker StructureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 3;

    can step with Folder entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        print("visit " + here.name);
        self.found.append(here.fid);
        if here.depth >= self.max_depth { disengage; }
        kids: list[Folder] = [];
        for ch in [here ->:CHILD:->][?:Folder] { kids.append(ch); }
        kids = sorted(kids, key=fid_of);
        visit kids;
    }
}
