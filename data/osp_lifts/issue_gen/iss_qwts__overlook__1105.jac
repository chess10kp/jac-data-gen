"""qwts/overlook#1105 — sidebar collections tree: flat DFS list and folder album counts."""

node Library {
    has lid: str = "lib";
}

node Collection {
    has cid: str;
    has name: str;
    has is_folder: bool = False;
    has sort_key: int = 0;
}

edge Child {}

def sort_collection_list(raw: list[Collection]) -> list[Collection] {
    out: list[Collection] = [];
    i: int = 0;
    while i < len(raw) {
        out.append(raw[i]);
        i += 1;
    }
    n: int = len(out);
    a: int = 0;
    while a < n {
        b: int = a + 1;
        while b < n {
            if out[b].sort_key < out[a].sort_key {
                tmp: Collection = out[a];
                out[a] = out[b];
                out[b] = tmp;
            }
            b += 1;
        }
        a += 1;
    }
    return out;
}

def lib_sorted_children(lib: Library) -> list[Collection] {
    raw: list[Collection] = [];
    for ch in [lib ->:Child:->][?:Collection] {
        raw.append(ch);
    }
    return sort_collection_list(raw);
}

def sort_children(parent: Collection) -> list[Collection] {
    raw: list[Collection] = [];
    for ch in [parent ->:Child:->][?:Collection] {
        raw.append(ch);
    }
    return sort_collection_list(raw);
}

def detach_collection(child: Collection) {
    libs: list[Library] = [child <-:Child:<-][?:Library];
    for lb in libs {
        lb del--> child;
    }
    pars: list[Collection] = [child <-:Child:<-][?:Collection];
    for pc in pars {
        pc del--> child;
    }
}

def collection_index(lib: Library) -> dict[str, Collection] {
    wk = lib spawn IndexWalker(claimed={}, store={});
    return wk.store;
}

walker IndexWalker {
    has claimed: dict[str, bool] = {};
    has store: dict[str, Collection] = {};

    can index_lib with Library entry {
        if self.lid_seen() {
            skip;
        }
        kids: list[Collection] = lib_sorted_children(here);
        i: int = 0;
        while i < len(kids) {
            visit [kids[i]];
            i += 1;
        }
        print(len(self.store));
    }

    can index_coll with Collection entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.store[here.cid] = here;
        kids: list[Collection] = sort_children(here);
        i: int = 0;
        while i < len(kids) {
            visit [kids[i]];
            i += 1;
        }
        print(here.cid);
    }

    def lid_seen -> bool {
        if "lib" in self.claimed {
            return True;
        }
        self.claimed["lib"] = True;
        return False;
    }
}

walker FlattenWalker {
    has claimed: dict[str, bool] = {};
    has out_ids: list[str] = [];

    can flat_lib with Library entry {
        if self.lid_seen() {
            skip;
        }
        kids: list[Collection] = lib_sorted_children(here);
        i: int = len(kids) - 1;
        while i >= 0 {
            visit :0: [kids[i]];
            i -= 1;
        }
        print(len(self.out_ids));
    }

    can flat_coll with Collection entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out_ids.append(here.cid);
        kids: list[Collection] = sort_children(here);
        if len(kids) == 0 {
            disengage;
        }
        j: int = len(kids) - 1;
        while j >= 0 {
            visit :0: [kids[j]];
            j -= 1;
        }
        print(here.cid);
    }

    def lid_seen -> bool {
        if "lib" in self.claimed {
            return True;
        }
        self.claimed["lib"] = True;
        return False;
    }
}

walker AlbumCountWalker {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can tally with Collection entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if not here.is_folder {
            self.count += 1;
        }
        kids: list[Collection] = sort_children(here);
        if len(kids) == 0 {
            disengage;
        }
        k: int = len(kids) - 1;
        while k >= 0 {
            visit :0: [kids[k]];
            k -= 1;
        }
        print(self.count);
    }
}

def seed_library(
    cids: list[str],
    names: list[str],
    parent_cids: list[str],
    is_folders: list[bool],
    sort_keys: list[int]
) -> Library {
    lib = Library(lid="lib");
    root ++> lib;
    by_id: dict[str, Collection] = {};
    i: int = 0;
    while i < len(cids) {
        nd = Collection(
            cid=cids[i],
            name=names[i],
            is_folder=is_folders[i],
            sort_key=sort_keys[i]
        );
        by_id[cids[i]] = nd;
        i += 1;
    }
    j: int = 0;
    while j < len(cids) {
        cid = cids[j];
        par_cid = parent_cids[j];
        coll = by_id[cid] as Collection;
        if par_cid == "" {
            lib +>:Child:+> coll;
        } else {
            par = by_id[par_cid] as Collection;
            par +>:Child:+> coll;
        }
        j += 1;
    }
    return lib;
}

def sidebar_flat_ids(lib: Library) -> list[str] {
    wk = lib spawn FlattenWalker(claimed={}, out_ids=[]);
    return wk.out_ids;
}

def folder_descendant_album_count(lib: Library, folder_id: str) -> int {
    idx: dict[str, Collection] = collection_index(lib);
    if folder_id not in idx {
        return 0;
    }
    target = idx[folder_id] as Collection;
    if not target.is_folder {
        return 0;
    }
    wk = target spawn AlbumCountWalker(claimed={}, count=0);
    return wk.count;
}

def reorder_sidebar(lib: Library, ordered_ids: list[str]) -> list[str] {
    idx: dict[str, Collection] = collection_index(lib);
    k: int = 0;
    for cid in ordered_ids {
        if cid in idx {
            nd = idx[cid] as Collection;
            nd.sort_key = k;
            k += 1;
        }
    }
    return sidebar_flat_ids(lib);
}

def move_album(lib: Library, album_id: str, dest_folder_id: str) -> bool {
    idx: dict[str, Collection] = collection_index(lib);
    if album_id not in idx {
        return False;
    }
    album = idx[album_id] as Collection;
    if album.is_folder {
        return False;
    }
    if dest_folder_id not in idx {
        return False;
    }
    dest = idx[dest_folder_id] as Collection;
    if not dest.is_folder {
        return False;
    }
    detach_collection(album);
    dest +>:Child:+> album;
    return True;
}
