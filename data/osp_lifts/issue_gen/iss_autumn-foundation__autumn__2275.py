"""Comment hard delete: scoped walk vs unscoped FK cascade accounting.

Before-code synthesized from autumn-foundation/autumn#2275: deleting a
comment subtree collects descendants by ``parent_id`` filtered to one
record scope ``(commentable_type, commentable_id)`` -- but the database's
ON DELETE CASCADE is NOT so scoped. An imported row can name a comment in
this subtree as parent while belonging to ANOTHER record: it vanishes
without appearing in the count and silently corrupts that other record's
comment counter. The fix computes the true cascade reach first (ignoring
scope), decrements every affected record by its own share, and reports an
honest total. Children adjacency maps per record; the unscoped reach is a
plain stack walk over the global child map. Reply depth levels are part
of the deletion report.
"""


class CrossRecordError(ValueError):
    """A cross-record edge was detected where policy forbids it."""


class CommentStore:
    def __init__(self):
        self.parent_of = {}   # comment -> parent | None (global join view)
        self.children_of = {} # comment -> [child ids]
        self.record_of = {}   # comment -> (type, id) scope tuple
        self.counts = {}      # (type, id) -> live comment count

    def _register(self, cid, record, parent_id):
        self.record_of[cid] = record
        self.parent_of[cid] = parent_id
        if parent_id is not None:
            self.children_of.setdefault(parent_id, []).append(cid)
        self.children_of.setdefault(cid, [])
        self.counts[record] = self.counts.get(record, 0) + 1

    def add_comment(self, cid, record, parent_id=None):
        """Framework write path: replies must stay inside the record."""
        if parent_id is not None:
            if parent_id not in self.parent_of:
                raise KeyError("unknown parent")
            if self.record_of[parent_id] != record:
                raise CrossRecordError("reply crosses record boundary")
        self._register(cid, record, parent_id)

    def import_comment(self, cid, record, parent_id):
        """Imported/migrated row: may carry a CROSS-RECORD parent link.

        This is exactly the shape issue #2275 warns about -- legal at the
        storage layer even though the write path can never produce it.
        """
        if parent_id is not None and parent_id not in self.parent_of:
            raise KeyError("unknown parent")
        self._register(cid, record, parent_id)

    def _walk(self, start, scoped_to=None):
        """Stack walk over the global child map.

        ``scoped_to`` prunes at comments outside that record; ``None``
        follows every edge like the raw FK cascade does.
        """
        out = []
        stack = [start]
        seen = set()
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            if scoped_to is not None and self.record_of[cur] != scoped_to:
                continue
            out.append(cur)
            stack.extend(self.children_of.get(cur, []))
        return out

    def scoped_subtree(self, cid):
        """What the recursive query collects: same-record replies only."""
        return sorted(self._walk(cid, scoped_to=self.record_of[cid]))

    def unscoped_cascade_reach(self, cid):
        """What ON DELETE CASCADE actually removes: everything reachable."""
        return sorted(self._walk(cid))

    def spill_set(self, cid):
        """Rows the DB removes but the scoped query never reported."""
        scoped = set(self.scoped_subtree(cid))
        allreach = set(self.unscoped_cascade_reach(cid))
        return sorted(allreach - scoped)

    def hard_delete_subtree(self, cid):
        """Honest two-phase delete with per-record counter repair.

        Phase 1 collects scoped ids + spill + depth report; phase 2
        applies removal and fixes EVERY affected record's counter.
        Returns {"scoped": n, "total": m, "levels": [...]}.
        """
        root_record = self.record_of[cid]
        reach = self._walk(cid)
        scoped = [c for c in reach if self.record_of[c] == root_record]
        spill = [c for c in reach if self.record_of[c] != root_record]
        # Depth levels of the scoped walk are observable in reports.
        levels = []
        frontier = [cid]
        seen = {cid}
        while frontier:
            nxt = []
            for cur in frontier:
                for ch in self.children_of.get(cur, []):
                    if ch in seen or self.record_of[ch] != root_record:
                        continue
                    seen.add(ch)
                    nxt.append(ch)
            if nxt:
                levels.append(nxt)
            frontier = nxt
        # Phase 2: decrement per record, then remove.
        per_record = {}
        for c in reach:
            rec = self.record_of[c]
            per_record[rec] = per_record.get(rec, 0) + 1
        for rec, cnt in per_record.items():
            self.counts[rec] = self.counts.get(rec, 0) - cnt
        removed = set(reach)
        for c in reach:
            p = self.parent_of.get(c)
            if p is not None and p not in removed:
                self.children_of[p] = [
                    x for x in self.children_of.get(p, []) if x != c
                ]
            self.children_of.pop(c, None)
            self.parent_of.pop(c, None)
            self.record_of.pop(c, None)
        return {
            "scoped": len(scoped),
            "total": len(reach),
            "spill": len(spill),
            "levels": [len(l) for l in levels],
        }
