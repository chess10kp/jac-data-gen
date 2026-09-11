"""Holder-chain analysis for transitive security alerts, lifted to OSP.

Locked packages become Package nodes; "depends on" entries become typed
Requires edges; the per-path DFS descent becomes a walker that carries
its own path and, at a branch point, spawns a fresh sub-walker for each
extra route -- one walker instance per holder chain. The current-path
membership check survives as the explicit simple-path/cycle policy.
Chains accumulate through a shared collector and are returned sorted;
an unreachable target yields [].
Ref: EdanStarfire/claudecode_webui#1815
"""
node Package {
    has name: str;
}
edge Requires {}

"""Lock handle: package names resolve through this lookup map."""
obj Lock {
    has packages: dict[str, Package];

    def resolve(name: str) -> Package | None {
        return self.packages.get(name);
    }
}

"""Deterministic fresh-graph builder from a {pkg: [deps]} lock spec."""
def load_lock(lock: dict) -> Lock {
    lk = Lock(packages={});
    names: set[str] = set();
    for k in lock.keys() {
        if k != "root" {
            names.add(k);
        }
        kdeps: list[str] = lock[k];
        for d in kdeps {
            names.add(d);
        }
    }
    for n in names {
        p = Package(name=n);
        root ++> p;
        lk.packages[n] = p;
    }
    for k in lock.keys() {
        if k == "root" {
            continue;
        }
        kdeps2: list[str] = lock[k];
        for d in kdeps2 {
            dep = lk.resolve(d);
            if dep is not None {
                lk.packages[k] +>:Requires:+> dep;
            }
        }
    }
    return lk;
}

"""One simple-path descent; branches fork into fresh sub-walkers."""
walker ChainWalk {
    has target: str;
    has path: list[str];
    has chains: list[list[str]];

    can step with Package entry {
        if here.name == self.target {
            self.chains.append(list(self.path));  # one holder chain complete
            disengage;
        }
        base: list[str] = list(self.path);  # path as it is at this node
        extended = False;
        for k in [here ->:Requires:->] {
            kd: Package = k;
            if kd.name in self.path {
                continue;  # simple paths only: no package twice in one chain
            }
            if extended {
                np: list[str] = list(base);
                np.append(kd.name);
                kd spawn ChainWalk(target=self.target, path=np, chains=self.chains);
            } else {
                self.path.append(kd.name);
                extended = True;
                visit [kd];
            }
        }
        if not extended {
            disengage;  # dead end: no route onward
        }
    }
}

"""All simple paths from the root's direct dependencies to ``target``, sorted."""
def holder_chains(lock: dict, target: str) -> list[list[str]] {
    lk = load_lock(lock);
    chains: list[list[str]] = [];
    roots: list[str] = lock.get("root", []);
    for direct in roots {
        d = lk.resolve(direct);
        if d is None {
            continue;
        }
        d spawn ChainWalk(target=target, path=[direct], chains=chains);
    }
    return sorted(chains);
}
