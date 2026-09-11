"""Tr3kkR/Yuzu#1362 — Management group reparent with cycle guard."""

node MgmtGroup {
    has gid: str;
}

edge ChildOf {}

obj GroupStore {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def _find(gid: str) -> MgmtGroup | None {
        for g in [self._root-->[?:MgmtGroup]] {
            if g.gid == gid {
                return g;
            }
        }
        return None;
    }

    def add_group(gid: str, parent_id: str | None = None) -> None {
        if self._find(gid) is not None {
            raise ValueError(f"duplicate group: {gid}");
        }
        g = self._root ++> MgmtGroup(gid=gid);
        if parent_id is not None {
            par = self._find(parent_id);
            if par is None {
                raise KeyError(parent_id);
            }
            par +>:ChildOf:+> g;
        }
    }

    def ancestors(gid: str) -> list[str] {
        g = self._find(gid);
        if g is None {
            raise KeyError(gid);
        }
        w = g spawn AncestorWalker();
        return w.out;
    }

    def descendants(gid: str) -> list[str] {
        g = self._find(gid);
        if g is None {
            raise KeyError(gid);
        }
        w = g spawn DescendantWalker();
        return sorted(w.hits);
    }

    def would_cycle(new_parent: str, gid: str) -> bool {
        par = self._find(new_parent);
        child = self._find(gid);
        if par is None or child is None {
            raise KeyError(new_parent if par is None else gid);
        }
        if new_parent == gid {
            return True;
        }
        w = par spawn AncestorWalker();
        return gid in w.out;
    }

    def reparent(gid: str, new_parent: str | None) -> None {
        g = self._find(gid);
        if g is None {
            raise KeyError(gid);
        }
        if new_parent is not None and self.would_cycle(new_parent, gid) {
            raise ValueError("cycle");
        }
        for old in [g<--][?:MgmtGroup] {
            old del ->:ChildOf:-> g;
        }
        if new_parent is not None {
            par = self._find(new_parent);
            if par is None {
                raise KeyError(new_parent);
            }
            par +>:ChildOf:+> g;
        }
    }
}

walker AncestorWalker {
    has out: list[str] = [];
    has seen: dict[str, bool] = {};

    can climb with MgmtGroup entry {
        for par in [here<--][?:MgmtGroup] {
            if par.gid in self.seen {
                skip;
            }
            self.seen[par.gid] = True;
            self.out.append(par.gid);
            visit [par];
        }
    }
}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can walk with MgmtGroup entry {
        visit [-->][?:MgmtGroup];
    }

    can step with MgmtGroup entry {
        if here.gid in self.claimed {
            skip;
        }
        self.claimed[here.gid] = True;
        self.hits.append(here.gid);
        visit [-->][?:MgmtGroup];
    }
}

def build_store() -> GroupStore {
    return GroupStore();
}
