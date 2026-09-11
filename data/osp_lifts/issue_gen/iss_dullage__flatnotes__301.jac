"""dullage/flatnotes#301 — recursive markdown index (OSP lift)."""

obj VfsStore {
    has stamp: int = 0;
}

node FsEntry {
    has path: str;
    has kind: str;
}

edge InDir {}

walker MdIndex {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with FsEntry entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.kind == "file" {
            if here.path.endswith(".md") { self.hits.append(here.path); }
            disengage;
        }
        visit [->:InDir:->][?:FsEntry] else { disengage; };
    }
}

def _find(path: str) -> FsEntry | None {
    for ent in [-->][?:FsEntry] {
        if ent.path == path { return ent; }
    }
    return None;
}

def load_vfs(entries: list[tuple[str, str, str | None]]) -> VfsStore {
    mp: dict[str, FsEntry] = {};
    for (p, k, _par) in entries {
        if p not in mp {
            fresh = FsEntry(path=p, kind=k);
            root ++> fresh;
            mp[p] = fresh;
        }
    }
    for (p, k, par) in entries {
        cur = mp.get(p, None);
        if cur is not None { cur.kind = k; }
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None {
                parent +>:InDir:+> child;
            }
        }
    }
    return VfsStore(stamp=1);
}

def index_markdown(g: VfsStore, `root: str) -> list[str] {
    _ = g;
    anchor = _find(`root);
    if anchor is None or anchor.kind != "folder" { return []; }
    w = anchor spawn MdIndex(claimed={}, hits=[]);
    return sorted(w.hits);
}
