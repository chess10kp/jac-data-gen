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


class Part:
    def __init__(self, pid, parent=None, qty=1):
        self.pid = pid
        self.parent = parent
        self.children = []
        self.qty = qty
        self.suppliers = []
        self.dead = False


class BomCatalog:
    def __init__(self):
        self.parts = {}   # pid -> Part
        self.lead = {}    # pid -> base lead days
        self.count = {}   # pid -> component count in subtree

    def add_part(self, pid, parent=None, qty=1, lead=0):
        if pid in self.parts:
            raise ValueError("duplicate part " + pid)
        if parent is not None and parent not in self.parts:
            raise KeyError(parent)
        p = self.parts[parent] if parent is not None else None
        part = Part(pid, p, qty)
        if p is not None:
            p.children.append(part)
        self.parts[pid] = part
        self.lead[pid] = lead
        self._recount_up(pid)
        return pid

    def _subtree_total(self, node):
        total = len(node.children)
        for c in node.children:
            total += self._subtree_total(c)
        return total

    def _recount_up(self, pid):
        cur = self.parts[pid]
        while cur is not None:
            self.count[cur.pid] = self._subtree_total(cur)
            cur = cur.parent

    def rate_supplier(self, pid, name):
        if name not in self.parts[pid].suppliers:
            self.parts[pid].suppliers.append(name)

    def suppliers_for(self, pid):
        """Suppliers of pid plus those inherited from ancestors."""
        out = set(self.parts[pid].suppliers)
        cur = self.parts[pid].parent
        while cur is not None:
            out.update(cur.suppliers)
            cur = cur.parent
        return sorted(out)

    def effective_lead(self, pid):
        kids = self.parts[pid].children
        best = 0
        for c in kids:
            best = max(best, self.effective_lead(c.pid))
        return self.lead[pid] + best

    def discontinue(self, pid):
        """Cascade: remove pid and all sub-parts. Returns sorted removed
        ids; recomputes ancestor component counts."""
        if pid not in self.parts:
            raise KeyError(pid)
        parent = self.parts[pid].parent
        doomed = []
        q = [pid]
        while q:
            cur = q.pop(0)
            doomed.append(cur)
            q.extend(c.pid for c in self.parts[cur].children)
        for d in doomed:
            part = self.parts.pop(d)
            part.dead = True
            self.lead.pop(d)
            self.count.pop(d, None)
        if parent is not None:
            parent.children = [c for c in parent.children if c.pid != pid]
            self._recount_up(parent.pid)
        return sorted(doomed)

    def component_count(self, pid):
        return self.count.get(pid, 0)
