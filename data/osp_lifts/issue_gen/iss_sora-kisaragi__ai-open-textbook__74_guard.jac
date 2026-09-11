"""Curriculum prerequisite-graph validation and route totals.

sora-kisaragi/ai-open-textbook#74 lifted to OSP: lessons become Lesson
archetypes and prerequisite references become typed Requires edges. The
checker's adjacency dict and frontier loops become claim-mapped walkers --
cycle detection is per-lesson self-reachability, the prerequisite closure is
a flood -- and results stay validity flags, sorted sets, and period sums.
"""
node Lesson {
    has lid: str;
    has unit: str;
    has periods: int = 0;
}
edge Requires {}

"""Handle: lesson ids resolve through this lookup map."""
obj Curriculum {
    has lessons: dict[str, Lesson];
    has dangling: dict[str, list[str]] = {};   # refs to undeclared lessons

    def resolve(lid: str) -> Lesson | None {
        return self.lessons.get(lid);
    }
}

def build_curriculum(items: list[tuple[str, str, int]],
                     prereqs: list[tuple[str, str]]) -> Curriculum {
    cur = Curriculum(lessons={});
    for (lid, unit, periods) in items {
        lsn = Lesson(lid=lid, unit=unit, periods=periods);
        root ++> lsn;
        cur.lessons[lid] = lsn;
    }
    for (lid, req) in prereqs {
        a = cur.lessons.get(lid);
        b = cur.lessons.get(req);
        if a is None {
            continue;
        }
        if b is not None {
            a +>:Requires:+> b;
        } else {
            # Unknown prerequisite: kept for the validation report.
            prev = cur.dangling.get(lid);
            if prev is None {
                cur.dangling[lid] = [req];
            } else {
                prev.append(req);
            }
        }
    }
    return cur;
}

walker PathProbe {
    has target: str = "";
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with Lesson entry {
        if not self.started {
            self.started = True;
            self.claimed[here.lid] = True;
            visit [->:Requires:->];
        } else {
            if here.lid == self.target {
                self.found = True;
                disengage;
            }
            if here.lid in self.claimed {
                skip;
            }
            self.claimed[here.lid] = True;
            visit [->:Requires:->];
        }
    }
}

walker NeedsHop {
    has outs: list[str] = [];
    has started: bool = False;

    can step with Lesson entry {
        if not self.started {
            self.started = True;
            visit [->:Requires:->];
        } else {
            if here.lid not in self.outs {
                self.outs.append(here.lid);
            }
        }
    }
}

walker NeedsFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_lid: str = "";

    can step with Lesson entry {
        if here.lid in self.claimed {
            skip;
        }
        if here.lid != self.start_lid {
            self.reached.append(here.lid);
        }
        self.claimed[here.lid] = True;
        visit [->:Requires:->];
    }
}

def _needs(cur: Curriculum, lid: str) -> list[str] {
    lsn = cur.resolve(lid);
    if lsn is None {
        return [];
    }
    w = lsn spawn NeedsHop();
    return w.outs;
}

"""True when the prerequisite graph contains a directed cycle."""
def has_cycle(cur: Curriculum) -> bool {
    for lid in cur.lessons.keys() {
        lsn = cur.lessons[lid];
        w = lsn spawn PathProbe(target=lid);
        if w.found {
            return True;
        }
    }
    return False;
}

"""Sorted ``lesson_id`` -> unknown ``required_id`` pairs as tuples."""
def missing_prereqs(cur: Curriculum) -> list[tuple] {
    out: list[tuple] = [];
    for lid in cur.dangling.keys() {
        for req in cur.dangling[lid] {
            out.append((lid, req));
        }
    }
    return sorted(out);
}

"""Sorted lesson ids without a positive period allocation."""
def unpositioned_lessons(cur: Curriculum) -> list[str] {
    out: list[str] = [];
    for lid in cur.lessons.keys() {
        if cur.lessons[lid].periods <= 0 {
            out.append(lid);
        }
    }
    return sorted(out);
}

"""Transitive prerequisite closure of one lesson (sorted, exclusive)."""
def prerequisites_of(cur: Curriculum, lesson_id: str) -> list[str] {
    lsn = cur.resolve(lesson_id);
    if lsn is None {
        return [];
    }
    w = lsn spawn NeedsFlood(start_lid=lesson_id);
    return sorted(w.reached);
}

"""Per-unit mandatory period totals as sorted (unit, periods) pairs."""
def unit_totals(cur: Curriculum) -> list[tuple] {
    totals: dict[str, int] = {};
    for lid in cur.lessons.keys() {
        lsn = cur.lessons[lid];
        prev = totals.get(lsn.unit);
        if prev is None {
            totals[lsn.unit] = lsn.periods;
        } else {
            totals[lsn.unit] = prev + lsn.periods;
        }
    }
    out: list[tuple] = [];
    for u in totals.keys() {
        out.append((u, totals[u]));
    }
    return sorted(out);
}
