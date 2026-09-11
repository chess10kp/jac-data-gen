node Pkg {
    has pkg_id: str;
    has name: str;
    has ver: str;
    has is_root: bool = False;
}
edge Depends {}

def lookup(pkg_id: str) -> Pkg | None {
    for nd in [root ->][?:Pkg] {
        if nd.pkg_id == pkg_id {
            return nd;
        }
    }
    return None;
}

def add_pkg(pkg_id: str, name: str, ver: str, is_root: bool) -> None {
    # create package node if not exists
    cur: Pkg | None = lookup(pkg_id);
    if cur is not None {
        return;
    }
    nd: Pkg = Pkg(pkg_id=pkg_id, name=name, ver=ver, is_root=is_root);
    root ++> nd;
}

def add_dep(src: str, dst: str) -> None {
    s: Pkg | None = lookup(src);
    d: Pkg | None = lookup(dst);
    if s is None {
        return;
    }
    if d is None {
        return;
    }
    s +>:Depends:+> d;
}

def find_dups() -> list[str] {
    seen: dict[str, dict[str, bool]] = {};
    for p in [root ->][?:Pkg] {
        if p.name not in seen {
            seen[p.name] = {};
        }
        seen[p.name][p.ver] = True;
    }
    out: list[str] = [];
    for n in seen {
        cnt: int = 0;
        for v in seen[n] {
            cnt += 1;
        }
        if cnt > 1 {
            out.append(n);
        }
    }
    return sorted(out);
}

def explain(pkg_name: str, cap: int) -> dict[str, list[list[str]]] {
    # map version -> chains (each chain leaf -> root)
    result: dict[str, list[list[str]]] = {};
    # collect distinct version instances for pkg_name
    pkgs: list[Pkg] = [];
    for p in [root ->][?:Pkg] {
        if p.name == pkg_name {
            pkgs.append(p);
        }
    }
    if len(pkgs) == 0 {
        return result;
    }
    for pkg in pkgs {
        w: Provenance = pkg spawn Provenance(start_id=pkg.pkg_id, cap=cap);
        chains: list[list[str]] = [];
        for r in w.roots {
            rev: list[str] = [];
            cur: str = r;
            rev.append(cur);
            while cur != w.start_id {
                if cur not in w.parent {
                    break;
                }
                cur = w.parent[cur];
                rev.append(cur);
            }
            # reverse to leaf -> root
            fwd: list[str] = [];
            idx: int = len(rev) - 1;
            while idx >= 0 {
                fwd.append(rev[idx]);
                idx -= 1;
            }
            # only keep valid chains that start with leaf
            if len(fwd) > 0 {
                if fwd[0] == w.start_id {
                    chains.append(fwd);
                }
            }
        }
        # cap already enforced by walker, sort for determinism
        # insertion order may vary, sort by string join
        result[pkg.ver] = chains;
        print(pkg.ver);
    }
    return result;
}

walker Provenance {
    has start_id: str = "";
    has cap: int = 3;
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has roots: list[str] = [];
    can trace with Pkg entry {
        if here.pkg_id in self.claimed {
            skip;
        }
        self.claimed[here.pkg_id] = True;
        print(here.pkg_id);
        if here.is_root {
            self.roots.append(here.pkg_id);
            # do not traverse beyond root
            if len(self.roots) >= self.cap {
                skip;
            }
            skip;
        }
        nxt: list[Pkg] = [here <-:Depends:-][?:Pkg];
        for p in nxt {
            if p.pkg_id not in self.parent {
                self.parent[p.pkg_id] = here.pkg_id;
            }
            if p.pkg_id not in self.claimed {
                # parent already recorded for later enumeration
            }
        }
        if len(nxt) > 0 {
            if len(self.roots) < self.cap {
                visit :0: nxt;
            } else {
                disengage;
            }
        } else {
            disengage;
        }
    }
}

walker DemoPrint {
    can demo with Pkg entry {
        print(here.pkg_id);
        skip;
    }
}

with entry {
    root spawn DemoPrint();
}
