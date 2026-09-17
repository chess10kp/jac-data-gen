node Course { has cid: str; has title: str; }
node Lesson { has lid: str; has dur: int = 0; }
edge HAS { }
edge NEXT { }

# audit record: query budget accounting for a resolved course graph
obj Audit {
    has queries: int = 0;
    has order: list[str] = [];
    has visited: dict[str, bool] = {};
    has worst: int = 0;
}

def lesson_ids(c: Course) -> list[str] {
    ids: list[str] = [];
    for l in [c ->:HAS:->][?:Lesson] { ids.append(l.lid); }
    return sorted(ids);
}

# single-batch load: walker visits every lesson exactly once (claim map),
# counting one query per node instead of N+1 per-lesson lookups
walker load_course {
    has audit: Audit | None = None;
    can start with Course entry {
        if self.audit is None { self.audit = Audit(); }
        self.audit.queries = self.audit.queries + 1;
        self.audit.order.append(here.cid);
        kids: list[Lesson] = [];
        for ch in [here ->:HAS:->][?:Lesson] { kids.append(ch); }
        if len(kids) == 0 { disengage; }
        visit kids;
    }
    can step with Lesson entry {
        if here.lid in self.audit.visited { skip; }
        self.audit.visited[here.lid] = True;
        self.audit.queries = self.audit.queries + 1;
        self.audit.order.append(here.lid);
        if here.dur > self.audit.worst { self.audit.worst = here.dur; }
        nx: list[Lesson] = [];
        for ch in [here ->:NEXT:->][?:Lesson] { nx.append(ch); }
        if len(nx) == 0 { disengage; }
        visit nx;
    }
}

# build fixture: course -> two branches -> shared diamond lesson
def build_fixture() -> Course {
    c = Course(cid="c1", title="Catalog");
    a = Lesson(lid="a", dur=5);
    b = Lesson(lid="b", dur=7);
    d = Lesson(lid="d", dur=3);
    e = Lesson(lid="e", dur=9);
    c +>:HAS:+> a;  c +>:HAS:+> d;
    a +>:NEXT:+> b;  b +>:NEXT:+> e;  d +>:NEXT:+> e;
    root ++> c;
    return c;
}

with entry {
    c = build_fixture();
    w = c spawn load_course();
    print("queries", w.audit.queries);
    print("order", sorted(w.audit.order));
    print("worst", w.audit.worst);
}
