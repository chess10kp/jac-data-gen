"""Supply chain bill of materials with supplier registry.

Assemblies contain sub-parts forming a BOM tree; parts carry supplier
ratings. Discontinuing a part cascades through its sub-parts and recomputes
component counts up the assembly tree. Lead times follow an ancestor-aware
rule: each part's effective lead is its own processing time plus the longest
sub-assembly chain below it.

Hand-rolled machinery:
- parent/children pointers with recursive descent and ancestor ascent (C1)
- cascade sweep over an explicit queue plus incremental count aggregation (C5)
"""
class Part {
    def init(self: Part, pid: Any, parent: Any = None, qty: Any = 1) -> object {
        self.pid = pid;
        self.parent = parent;
        self.children = [];
        self.qty = qty;
        self.suppliers = [];
        self.dead = False;
    }
}
class BomCatalog {
    def init(self: BomCatalog) -> object {
        self.parts = {};
        self.lead = {};
        self.count = {};
    }
    def add_part(
        self: BomCatalog, pid: Any, parent: Any = None, qty: Any = 1, lead: Any = 0
    ) -> object {
        if (pid in self.parts) {
            raise ValueError("duplicate part");
        }
        if ((parent is not None) and (parent not in self.parts)) {
            raise KeyError(parent);
        }
        p = self.parts[parent] if (parent is not None) else None;
        part = Part(pid, p, qty);
        if (p is not None) {
            p.children.append(part);
        }
        self.parts[pid] = part;
        self.lead[pid] = lead;
        self._recount_up(pid);
        return pid;
    }
    def _subtree_total(self: BomCatalog, p: Part) -> int {
        kids = p.children as list;
        total = len(kids);
        for c in kids {
            cr = c as Part;
            total += self._subtree_total(cr);
        }
        return total;
    }
    def _recount_up(self: BomCatalog, pid: Any) -> object {
        cur2: Part | None = self.parts[pid] as Part | None;
        while (cur2 is not None) {
            cp = cur2.pid;
            self.count[cp] = self._subtree_total(cur2 as Part);
            up = cur2.parent as Part | None;
            cur2 = up;
        }
    }
    def rate_supplier(self: BomCatalog, pid: Any, name: Any) -> object {
        if (name not in self.parts[pid].suppliers) {
            self.parts[pid].suppliers.append(name);
        }
    }
    """Suppliers of pid plus those inherited from ancestors."""
    def suppliers_for(self: BomCatalog, pid: Any) -> object {
        out = set();
        pp = self.parts[pid] as Part;
        for sname in pp.suppliers as list {
            out.add(sname);
        }
        cur: Part | None = pp.parent as Part | None;
        while (cur is not None) {
            for sname2 in cur.suppliers as list {
                out.add(sname2);
            }
            nxt = cur.parent as Part | None;
            cur = nxt;
        }
        return sorted(out);
    }
    def effective_lead(self: BomCatalog, pid: Any) -> int {
        pp = self.parts[pid] as Part;
        kids = pp.children as list;
        best = 0;
        for c in kids {
            cr = c as Part;
            best = max(best, self.effective_lead(cr.pid));
        }
        my_lead: int = self.lead[pid] as int;
        return (my_lead + best);
    }
    """Cascade: remove pid and all sub-parts. Returns sorted removed
        ids; recomputes ancestor component counts."""
    def discontinue(self: BomCatalog, pid: Any) -> object {
        if (pid not in self.parts) {
            raise KeyError(pid);
        }
        parent = self.parts[pid].parent;
        doomed = [];
        q = [pid];
        while q {
            cur = q.pop(0);
            doomed.append(cur);
            kids = (self.parts[cur] as Part).children as list;
            for c in kids {
                cr = c as Part;
                q.append(cr.pid);
            }
        }
        for d in doomed {
            part = self.parts.pop(d);
            part.dead = True;
            self.lead.pop(d);
            self.count.pop(d, None);
        }
        if (parent is not None) {
            pr = parent as Part;
            kept = [];
            for c in pr.children as list {
                cr = c as Part;
                if (cr.pid != pid) {
                    kept.append(cr);
                }
            }
            pr.children = kept;
            prr = pr.pid;
            self._recount_up(prr);
        }
        return sorted(doomed);
    }

    def component_count(self: BomCatalog, pid: Any) -> object {
        return self.count.get(pid, 0);
    }
}

