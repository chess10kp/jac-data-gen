"""University degree auditor lifted to OSP.

Courses become Course nodes; prerequisites become directed Unlocks edges.
The shared-deque multi-source flood becomes a claiming walker spawned once
per completed course, all sharing one claim map — that map is the explicit
cycle policy for prerequisite loops in messy catalogs.
"""
node Course {
    has code: str;
}
edge Unlocks {}

"""Loader handle: course codes resolve through this lookup map."""
obj Catalog {
    has courses: dict[str, Course];

    def resolve(code: str) -> Course | None {
        return self.courses.get(code);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_catalog(codes: list[str], unlocks: list[tuple[str, str]]) -> Catalog {
    cat = Catalog(courses={});
    for c in codes {
        n = Course(code=c);
        root ++> n;
        cat.courses[c] = n;
    }
    for (pre, post) in unlocks {
        a = cat.courses[pre];
        b = cat.courses[post];
        a +>:Unlocks:+> b;
    }
    return cat;
}

walker UnlockFlood {
    has claimed: dict[str, bool] = {};
    has seeding: bool = True;

    can step with Course entry {
        if not self.seeding and here.code in self.claimed {
            skip;
        }
        self.claimed[here.code] = True;
        self.seeding = False;
        visit [->:Unlocks:->] else { disengage; }
    }
}

walker OneHop {
    has names: list[str] = [];
    has claimed: dict[str, bool] = {};
    has seeding: bool = True;

    can step with Course entry {
        if self.seeding {
            self.seeding = False;
            self.claimed[here.code] = True;
            visit [->:Unlocks:->] else { disengage; }
        } else {
            if here.code in self.claimed {
                skip;
            }
            self.claimed[here.code] = True;
            self.names.append(here.code);
        }
    }
}

"""Courses reachable forward from any code in ``done``, excluding the
done set itself (sorted). Unknown codes in ``done`` are ignored."""
def unlocked_by(cat: Catalog, done: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    seeds: list[Course] = [];
    seen_done: dict[str, bool] = {};
    for c in done {
        seen_done[c] = True;
        crs = cat.resolve(c);
        if crs is None {
            continue;
        }
        if c not in claimed {
            claimed[c] = True;
            seeds.append(crs);
        }
    }
    for seed in seeds {
        _ = seed spawn UnlockFlood(claimed=claimed);
    }
    out: list[str] = [];
    for code in claimed {
        if code not in seen_done {
            out.append(code);
        }
    }
    return sorted(out);
}

"""Courses unlocked immediately by passing ``code`` (sorted)."""
def direct_unlocks(cat: Catalog, code: str) -> list[str] {
    start = cat.resolve(code);
    if start is None {
        return [];
    }
    w = start spawn OneHop();
    return sorted(w.names);
}

test "single source unlocks full chain" {
    cat = build_catalog(["CS101", "CS102", "CS201", "MA101", "CS301"], [("CS101", "CS102"), ("CS102", "CS201"), ("CS201", "CS301"), ("MA101", "CS201")]);
    assert unlocked_by(cat, ["CS101"]) == ["CS102", "CS201", "CS301"];
    assert unlocked_by(cat, ["MA101"]) == ["CS201", "CS301"];
}

test "multi-source union merges chains and excludes done set" {
    cat = build_catalog(["CS101", "CS102", "CS201", "MA101", "CS301"], [("CS101", "CS102"), ("CS102", "CS201"), ("CS201", "CS301"), ("MA101", "CS201")]);
    assert unlocked_by(cat, ["CS101", "MA101"]) == ["CS102", "CS201", "CS301"];
    assert unlocked_by(cat, ["CS101", "CS102"]) == ["CS201", "CS301"];
    assert unlocked_by(cat, []) == [];
}

test "prereq loop terminates" {
    cat = build_catalog(["X", "Y"], [("X", "Y"), ("Y", "X")]);
    assert unlocked_by(cat, ["X"]) == ["Y"];
}

test "direct unlocks one hop only" {
    cat = build_catalog(["CS101", "CS102", "CS201"], [("CS101", "CS102"), ("CS102", "CS201")]);
    assert direct_unlocks(cat, "CS101") == ["CS102"];
    assert direct_unlocks(cat, "CS201") == [];
    assert direct_unlocks(cat, "NOPE") == [];
}
