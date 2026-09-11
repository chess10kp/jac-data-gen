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

test "duplicated detection" {
    add_pkg("a1", "lru-cache", "10.4.3", False);
    add_pkg("a2", "lru-cache", "6.0.0", False);
    add_pkg("b1", "cacache", "18.0.0", False);
    dups: list[str] = find_dups();
    assert("lru-cache" in dups);
    assert(len(dups) == 1);
}

test "diamond revisit provenance" {
    add_pkg("r1", "app", "1.0", True);
    add_pkg("ma", "mid-a", "1.0", False);
    add_pkg("mb", "mid-b", "1.0", False);
    add_pkg("leaf1", "leaf", "1.0", False);
    # adversarial insertion order: second branch first
    add_dep("r1", "mb");
    add_dep("r1", "ma");
    add_dep("mb", "leaf1");
    add_dep("ma", "leaf1");
    res: dict[str, list[list[str]]] = explain("leaf", 5);
    assert("1.0" in res);
    chains: list[list[str]] = res["1.0"];
    assert(len(chains) >= 1);
    # every chain starts at leaf and ends at root
    for ch in chains {
        assert(ch[0] == "leaf1");
        assert(ch[len(ch) - 1] == "r1");
    }
    # claim-map ensures no infinite loop on revisit
    assert(len(chains) <= 2);
}

test "cycle tolerance" {
    add_pkg("cr", "app2", "1.0", True);
    add_pkg("ca", "cyc-a", "1.0", False);
    add_pkg("cb", "cyc-b", "1.0", False);
    add_pkg("dup1", "dup-pkg", "1.0", False);
    add_pkg("dup2", "dup-pkg", "2.0", False);
    add_dep("cr", "ca");
    add_dep("ca", "cb");
    add_dep("cb", "ca");
    add_dep("ca", "dup1");
    add_dep("cb", "dup2");
    dups2: list[str] = find_dups();
    assert("dup-pkg" in dups2);
    res1: dict[str, list[list[str]]] = explain("dup-pkg", 2);
    assert("1.0" in res1);
    assert("2.0" in res1);
    for v in res1 {
        for ch in res1[v] {
            assert(len(ch) >= 1);
        }
    }
}

test "unknown id tolerance and cap" {
    add_pkg("r2", "app3", "1.0", True);
    add_pkg("x1", "shared", "1.0", False);
    add_pkg("r3", "app4", "1.0", True);
    add_pkg("r4", "app5", "1.0", True);
    add_dep("r2", "x1");
    add_dep("r3", "x1");
    add_dep("r4", "x1");
    # unknown dep should be tolerated
    add_dep("nope", "x1");
    add_dep("r2", "missing");
    res_cap1: dict[str, list[list[str]]] = explain("shared", 1);
    assert("1.0" in res_cap1);
    assert(len(res_cap1["1.0"]) == 1);
    res_all: dict[str, list[list[str]]] = explain("shared", 10);
    assert(len(res_all["1.0"]) >= 1);
    assert(len(res_all["1.0"]) <= 3);
    empty: dict[str, list[list[str]]] = explain("not-exist", 5);
    assert(len(empty) == 0);
}

test "provenance sorted and duplicate version chains" {
    add_pkg("imp1", "myapp", "1.0", True);
    add_pkg("libA1", "lru-cache", "10.4.3", False);
    add_pkg("libA2", "lru-cache", "6.0.0", False);
    add_pkg("mid1", "cacache", "5.0.0", False);
    add_dep("imp1", "mid1");
    add_dep("mid1", "libA1");
    add_dep("imp1", "libA2");
    dups3: list[str] = find_dups();
    assert(sorted(dups3) == dups3);
    res: dict[str, list[list[str]]] = explain("lru-cache", 2);
    assert("10.4.3" in res);
    assert("6.0.0" in res);
    # 10.4.3 chain should go via cacache
    found_via: bool = False;
    for ch in res["10.4.3"] {
        if "mid1" in ch {
            found_via = True;
        }
    }
    assert(found_via);
}
