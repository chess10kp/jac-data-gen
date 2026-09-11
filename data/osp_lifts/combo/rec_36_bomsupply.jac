"""Supply chain BOM catalog, lifted to OSP.

Parts form a Contains tree; suppliers are nodes linked by SuppliedBy
cross-links. Component counts are incrementally maintained aggregates.
Discontinuing follows the two-phase protocol: a walker collects the doomed
subtree once-only, the facade disconnects edges, marks parts dead and drops
registry entries outside the walk, then ancestor counts are recomputed by a
linear ascent walker. Cycle policy: the tree is acyclic by construction;
sweeps still carry skip-guards because shared sub-assemblies re-enter nodes.
"""
node Part {
    has pid: str;
    has qty: int;
    has dead: bool = False;
}

node Supplier {
    has name: str;
}

"""BOM tree: assembly +>:Contains:+> sub-part."""
edge Contains {}

"""Supply cross-link: part is supplied by supplier."""
edge SuppliedBy {}

walker CascadeCollector {
    """Queue-equivalent descendant sweep over Contains; once-only."""
    has claimed: dict[str, bool] = {};
    has doomed: set[str] = set();

    can step with Part entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.doomed.add(here.pid);
        visit [->:Contains:->];
    }
}

walker LeadProbe {
    """Descends Contains edges accumulating lead days per path; each
    branch continues in its own spawned instance so accumulators never
    mix across paths. Reports the longest chain through its root."""
    has leads: dict[str, int];
    has acc_in: int = 0;
    has best: int = 0;

    can step with Part entry {
        my_acc: int = self.acc_in + self.leads.get(here.pid, 0);
        if my_acc > self.best {
            self.best = my_acc;
        }
        kids: list[Part] = [here ->:Contains:->];
        for k in kids {
            sub: LeadProbe = k spawn LeadProbe(leads=self.leads, acc_in=my_acc);
            if sub.best > self.best {
                self.best = sub.best;
            }
        }
    }
}

walker CountAscent {
    """Linear ascent over Contains recomputing each ancestor's subtree
    count. Dead ends at the tree root disengage."""
    has cat: BomCatalog;

    can step with Part entry {
        self.cat.count[here.pid] = self.cat._subtree_total(here);
        visit [here <-:Contains:<-] else { disengage; }
    }
}

walker SupplierAscent {
    """Linear climb gathering supplier names from the entry part and
    every ancestor above it."""
    has names: set[str] = set();

    can step with Part entry {
        sups: list[Supplier] = [here ->:SuppliedBy:->];
        for s in sups {
            self.names.add(s.name);
        }
        visit [here <-:Contains:<-] else { disengage; }
    }
}

obj BomCatalog {
    """Compatibility facade. Part ids and supplier names are public API
    currency; lookup maps are domain state."""
    has by_pid: dict[str, Part] = {};
    has by_name: dict[str, Supplier] = {};
    has lead: dict[str, int] = {};
    has count: dict[str, int] = {};

    def add_part(pid: str, parent: str | None = None, qty: int = 1, lead: int = 0) -> str {
        if pid in self.by_pid {
            raise ValueError("duplicate part " + pid);
        }
        p := Part(pid=pid, qty=qty);
        if parent is not None {
            par = self.by_pid[parent];
            par +>:Contains:+> p;
        }
        self.by_pid[pid] = p;
        self.lead[pid] = lead;
        self._recount_up(pid);
        return pid;
    }

    def _subtree_total(p: Part) -> int {
        kids: list[Part] = [p ->:Contains:->];
        total: int = len(kids);
        for k in kids {
            total += self.count.get(k.pid, 0);
        }
        return total;
    }

    def _recount_up(pid: str) -> None {
        # spawn the linear ascent; it recounts pid and every ancestor
        self.by_pid[pid] spawn CountAscent(cat=self);
    }

    def rate_supplier(pid: str, name: str) -> None {
        s = self.by_name.get(name);
        if s is None {
            s = Supplier(name=name);
            self.by_name[name] = s;
        }
        existing: list[Supplier] = [self.by_pid[pid] ->:SuppliedBy:->];
        if s not in existing {
            self.by_pid[pid] +>:SuppliedBy:+> s;
        }
    }

    def suppliers_for(pid: str) -> list[str] {
        # spawn the climb: own suppliers plus every ancestor's
        w = self.by_pid[pid] spawn SupplierAscent();
        return sorted(w.names);
    }

    """Effective lead = own processing plus the longest sub-assembly
    chain below. Each branch gets its own probe instance, keeping the
    accumulation path-scoped."""
    def effective_lead(pid: str) -> int {
        w: LeadProbe = self.by_pid[pid] spawn LeadProbe(
            leads=self.lead, acc_in=0
        );
        return w.best;
    }

    """Two-phase discontinue. Phase 1 collects the doomed set; phase 2
    severs edges, retires parts and recomputes surviving ancestors."""
    def discontinue(pid: str) -> list[str] {
        if pid not in self.by_pid {
            raise KeyError(pid);
        }
        w: CascadeCollector = self.by_pid[pid] spawn CascadeCollector();
        doomed: set[str] = w.doomed;
        parent: Part | None = None;
        ups: list[Part] = [self.by_pid[pid] <-:Contains:<-];
        if len(ups) > 0 {
            parent = ups[0];
        }
        for d in doomed {
            r = self.by_pid.pop(d);
            r.dead = True;
            self.lead.pop(d, None);
            self.count.pop(d, None);
            kids: list[Part] = [r ->:Contains:->];
            for k in kids {
                r del ->:Contains:-> k;
            }
            for up in [r <-:Contains:<-] {
                up del ->:Contains:-> r;
            }
            sups: list[Supplier] = [r ->:SuppliedBy:->];
            for s in sups {
                r del ->:SuppliedBy:-> s;
            }
        }
        if parent is not None {
            self._recount_up(parent.pid);
        }
        return sorted(doomed);
    }

    def component_count(pid: str) -> int {
        return self.count.get(pid, 0);
    }
}
