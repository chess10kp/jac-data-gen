"""Demand-driven incremental recomputation, lifted to OSP.

Context packs become Pack nodes carrying their stored result hash;
depends-on entries become typed Depends edges. The lazy dirty BFS
becomes a walker over the reverse edge direction (claim map = the
once-per-pack guard; diamond confluence and dependency cycles both
terminate). The demand-driven settlement becomes a walker that, on
arrival at a dirty pack, spawns sub-walkers into its unsettled dirty
dependencies (post-order settlement: dependencies hold their final
hashes before the pack derives its own), then either cleans -- the
recomputed hash is identical, early cutoff, no dependent is spawned
into -- or recomputes and spawns into its unsettled dirty dependents.
``results`` is never mutated; the graph is built fresh per call.
Ref: nateschmiedehaus/LiBrainian#93
"""
node Pack {
    has pid: str;
    has hash: str | None = None;
}
edge Depends {}

"""Pack-graph handle: pack ids resolve through this lookup map."""
obj PackGraph {
    has packs: dict[str, Pack];
    has nodes: dict[str, Pack];

    def resolve(pid: str) -> Pack | None {
        return self.nodes.get(pid);
    }
}

"""Deterministic fresh-graph builder from a {pack: [deps]} spec."""
def load_packs(graph: dict, results: dict) -> PackGraph {
    pg = PackGraph(packs={}, nodes={});
    names: set[str] = set(graph.keys());
    for k in graph.keys() {
        gd: list[str] = graph[k];
        for d in gd {
            names.add(d);
        }
    }
    for n in names {
        p = Pack(pid=n);
        root ++> p;
        pg.nodes[n] = p;
    }
    for k in graph.keys() {
        pg.packs[k] = pg.nodes[k];
    }
    for k in graph.keys() {
        gd: list[str] = graph[k];
        for d in gd {
            dep = pg.resolve(d);
            if dep is not None {
                pg.nodes[k] +>:Depends:+> dep;
            }
        }
    }
    for k in results.keys() {
        rp = pg.resolve(k);
        if rp is not None {
            rv: str = results[k];
            rp.hash = rv;
        }
    }
    return pg;
}

"""Lazy invalidation sweep: packs that depend on the spawn point."""
walker DirtyWalk {
    has claimed: dict[str, bool] = {};
    has hit: list[str] = [];

    can step with Pack entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.hit.append(here.pid);
        visit [<-:Depends:<-];  # reverse direction: packs that depend on me
    }
}

"""Sorted ids of every pack dirtied by ``changed`` (BFS closure)."""
def mark_dirty(graph: dict, changed: list[str]) -> list[str] {
    pg = load_packs(graph, {});
    claimed: dict[str, bool] = {};
    hit: list[str] = [];
    for c in changed {
        n = pg.resolve(c);
        if n is None {
            continue;  # changed ids nowhere in the graph are ignored
        }
        n spawn DirtyWalk(claimed=claimed, hit=hit);
    }
    return sorted(hit);
}

"""Demand-driven settlement of one dirty pack (deps settle first)."""
walker SettleWalk {
    has pg: PackGraph;
    has dirty: dict[str, bool];
    has chset: dict[str, bool];
    has settled: dict[str, bool];
    has recomputed: list[str];
    has cleaned: list[str];

    can step with Pack entry {
        if here.pid in self.settled {
            skip;
        }
        self.settled[here.pid] = True;
        dep_names: list[str] = [];
        for d in [here ->:Depends:->] {
            dn: Pack = d;
            dep_names.append(dn.pid);
        }
        # settle dirty dependencies first: final hashes before deriving
        for dn in sorted(dep_names) {
            if dn in self.dirty and dn not in self.settled {
                dp = self.pg.resolve(dn);
                if dp is not None {
                    dp spawn SettleWalk(pg=self.pg, dirty=self.dirty, chset=self.chset,
                                        settled=self.settled, recomputed=self.recomputed,
                                        cleaned=self.cleaned);
                }
            }
        }
        new: str;
        if here.pid in self.chset {
            new = f"src:{here.pid}";
        } else {
            parts: list[str] = [];
            for dn in sorted(dep_names) {
                dp = self.pg.resolve(dn);
                if dp is not None {
                    h = dp.hash;
                    if h is None {
                        h = "";  # missing stored hash reads as empty
                    }
                    parts.append(dn + "=" + h);
                }
            }
            new = "f:" + here.pid + "(" + ",".join(parts) + ")";
        }
        if new == here.hash {
            self.cleaned.append(here.pid);  # early cutoff: no dependent spawns
        } else {
            here.hash = new;
            self.recomputed.append(here.pid);
            dependent_names: list[str] = [];
            for u in [here <-:Depends:<-] {
                un: Pack = u;
                dependent_names.append(un.pid);
            }
            for un in sorted(dependent_names) {
                if un in self.dirty and un not in self.settled {
                    up = self.pg.resolve(un);
                    if up is not None {
                        up spawn SettleWalk(pg=self.pg, dirty=self.dirty, chset=self.chset,
                                            settled=self.settled, recomputed=self.recomputed,
                                            cleaned=self.cleaned);
                    }
                }
            }
        }
    }
}

"""Demand-driven recompute with early cutoff; ``results`` never mutated."""
def recompute(graph: dict, results: dict, changed: list[str]) -> dict {
    pg = load_packs(graph, results);
    # lazy mark first: the dirty closure (shared claim-guarded sweep)
    claimed: dict[str, bool] = {};
    dhit: list[str] = [];
    dirty: dict[str, bool] = {};
    for c in changed {
        n = pg.resolve(c);
        if n is None {
            continue;
        }
        n spawn DirtyWalk(claimed=claimed, hit=dhit);
    }
    for h in dhit {
        dirty[h] = True;
    }
    chset: dict[str, bool] = {};
    for c in changed {
        chset[c] = True;
    }
    settled: dict[str, bool] = {};
    recomputed: list[str] = [];
    cleaned: list[str] = [];
    for c in sorted(chset.keys()) {
        if c in pg.packs {
            n = pg.resolve(c);
            if n is not None {
                n spawn SettleWalk(pg=pg, dirty=dirty, chset=chset, settled=settled,
                                   recomputed=recomputed, cleaned=cleaned);
            }
        }
    }
    return {"recomputed": sorted(recomputed), "cleaned": sorted(cleaned)};
}
