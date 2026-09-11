"""Waishnav/devspace#90 — recursive workspace agent-file discovery (OSP lift)."""

obj WorkspaceStore {
    has stamp: int = 0;
}

node Dir {
    has path: str;
    has has_agent: bool;
}

edge ChildDir {}

walker AgentDiscover {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Dir entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.has_agent { self.hits.append(here.path); }
        visit [->:ChildDir:->][?:Dir];
    }
}

def _find(path: str) -> Dir | None {
    for d in [-->][?:Dir] {
        if d.path == path { return d; }
    }
    return None;
}

def load_tree(specs: list[tuple[str, str | None, bool]]) -> WorkspaceStore {
    mp: dict[str, Dir] = {};
    for (p, _par, has_md) in specs {
        if p not in mp {
            n = Dir(path=p, has_agent=has_md);
            root ++> n;
            mp[p] = n;
        }
    }
    for (p, par, has_md) in specs {
        d = mp.get(p, None);
        if d is not None { d.has_agent = has_md; }
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None {
                parent +>:ChildDir:+> child;
            }
        }
    }
    return WorkspaceStore(stamp=1);
}

def discover_agent_files(g: WorkspaceStore, root_path: str) -> list[str] {
    _ = g;
    anchor = _find(root_path);
    if anchor is None { return []; }
    w = anchor spawn AgentDiscover(claimed={}, hits=[]);
    return sorted(w.hits);
}
