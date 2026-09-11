"""naveed949/sandcastle#20 — Unified multi-repository workflows and Mission Control."""

obj MissionHandle {
    has blocked: set[str] = set();
}

node Repo {
    has name: str;
}

edge Depends {}

def _find(name: str) -> Repo | None {
    for r in [-->][?:Repo] {
        if r.name == name {
            return r;
        }
    }
    return None;
}

def load_mission(
    repos: list[str],
    depends: list[tuple[str, str]],
    blocked: list[str] | None = None,
) -> MissionHandle {
    mp: dict[str, Repo] = {};
    for nm in repos {
        if nm not in mp {
            r = Repo(name=nm);
            root ++> r;
            mp[nm] = r;
        }
    }
    for (repo, dep) in depends {
        if repo not in mp or dep not in mp {
            raise KeyError("unknown repo");
        }
        mp[repo] +>:Depends:+> mp[dep];
    }
    return MissionHandle(blocked=set(blocked or []));
}

def repo_build_order(m: MissionHandle) -> list[str] | None {
    _ = m;
    indeg: dict[str, int] = {};
    for r in [-->][?:Repo] {
        indeg[r.name] = len([r ->:Depends:->][?:Repo]);
    }
    out: list[str] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        out += ready;
        nxt: list[str] = [];
        for nm in ready {
            cur = _find(nm);
            if cur is None {
                continue;
            }
            for dep in [cur <-:Depends:<-][?:Repo] {
                indeg[dep.name] -= 1;
                if indeg[dep.name] == 0 {
                    nxt.append(dep.name);
                }
            }
        }
        ready = sorted(nxt);
    }
    return out if len(out) == len(indeg) else None;
}

walker BlockedSpread {
    has blocked: set[str] = set();
    has claimed: dict[str, bool] = {};
    has affected: list[str] = [];

    can seed with Root entry {
        for r in [-->][?:Repo] {
            if r.name in self.blocked {
                visit [r];
            }
        }
    }

    can step with Repo entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.affected.append(here.name);
        visit [here <-:Depends:<-][?:Repo];
    }
}

def blocked_repos(m: MissionHandle) -> list[str] {
    w = root spawn BlockedSpread(blocked=m.blocked, claimed={}, affected=[]);
    merged: set[str] = set(w.affected);
    for nm in m.blocked {
        merged.add(nm);
    }
    return sorted(merged);
}
