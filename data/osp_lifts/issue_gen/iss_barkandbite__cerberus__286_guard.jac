"""Stylesheet import inlining lifted to OSP (barkandbite/cerberus#286).

The stylesheet pool becomes ``Sheet`` nodes whose @import statements become
typed ``Imports`` edges; the recursive splice with its bookkeeping
containers dies. All mutable state lives on per-instance obj handles
(``StyleSheetPool``, ``Inliner``), so every test constructs fresh
instances -- no module-level globals, no leakage between tests. The
public API matches the source: ``register`` overwrites duplicates
silently, ``fetch`` counts each call into persistent per-URL counters,
the depth cap stops BEFORE fetching at ``depth == max_depth``, and an
exhausted budget raises ``BudgetExceeded`` (a ``RuntimeError``).
"""


"""The inline pass hit its fetch budget."""
class BudgetExceeded(RuntimeError) {}


node Sheet {
    has url: str;
    has body: str;
}


edge Imports: Sheet --> Sheet {}


"""Per-instance pool handle: the id -> node lookup map is domain API."""
obj StyleSheetPool {
    has sheets: dict[str, Sheet] = {};
    has fetches: dict[str, int] = {};
    has pending_wires: list[tuple[str, str]] = [];

    # duplicate registration overwrites silently (source: dict assign)
    def register(url: str, body: str, imports: list[str]) -> None {
        s = self.sheets.get(url);
        if s is None {
            s = Sheet(url=url, body=body);
            root ++> s;
            self.sheets[url] = s;
        } else {
            s.body = body;
            for old in [s ->:Imports:->] {
                s del ->:Imports:-> old;
            }
            kept: list[tuple[str, str]] = [];
            for w in self.pending_wires {
                if w[0] != url {
                    kept.append(w);
                }
            }
            self.pending_wires = kept;
        }
        # deferred wiring: targets may be registered after their importer;
        # wire everything resolvable now so fetch sees imports immediately
        for target in imports {
            dup = False;
            for w in self.pending_wires {
                if w[0] == url and w[1] == target {
                    dup = True;
                }
            }
            if self.sheets.get(target) is not None {
                for t in [s ->:Imports:->] {
                    if t.url == target {
                        dup = True;
                    }
                }
            }
            if not dup {
                self.pending_wires.append((url, target));
            }
        }
        self.wire_pending();
    }

    def wire_pending() -> None {
        # connect typed edges only through registry lookups; unresolved
        # targets stay pending so fetching them fails closed until wired
        remaining: list[tuple[str, str]] = [];
        for pair in self.pending_wires {
            src = self.sheets.get(pair[0]);
            dst = self.sheets.get(pair[1]);
            if src is not None and dst is not None {
                src +>:Imports:+> dst;
            } else {
                remaining.append(pair);
            }
        }
        self.pending_wires = remaining;
    }

    def fetch(url: str) -> dict[str, any] {
        s = self.sheets.get(url);
        if s is None {
            raise KeyError(url);
        }
        self.fetches[url] = self.fetches.get(url, 0) + 1;
        imports: list[str] = [];
        for t in [s ->:Imports:->] {
            imports.append(t.url);
        }
        return {"body": s.body, "imports": imports};
    }

    def fetch_count(url: str) -> int {
        # counters persist across inline runs (never cleared)
        return self.fetches.get(url, 0);
    }
}


walker InlineWalk {
    """Fetch-once walk over Imports edges with depth + budget bounds."""
    has inliner: Inliner;
    has depth_left: int;

    can go with Sheet entry {
        # depth cap hits BEFORE fetching (source returns at depth == max_depth)
        if self.depth_left <= 0 {
            return;
        }
        if here.url in self.inliner.seen {
            return;  # repeat import: fetch nothing
        }
        if self.inliner.spent >= self.inliner.max_fetches {
            raise BudgetExceeded("fetch budget exhausted");
        }
        self.inliner.pool.fetch(here.url);  # public fetch increments the counter
        self.inliner.spent += 1;
        self.inliner.seen[here.url] = True;
        for nxt in [here ->:Imports:->] {
            nxt spawn InlineWalk(
                inliner=self.inliner, depth_left=self.depth_left - 1
            );
        }
    }
}


obj Inliner {
    has pool: StyleSheetPool;
    has max_depth: int = 4;
    has max_fetches: int = 1000;
    has seen: dict[str, bool] = {};
    has spent: int = 0;

    # Sorted urls transitively reachable via @import from root. Each url
    # fetched once regardless of how many sheets import it; depth cap and
    # fetch budget are enforced; the root itself is not part of the
    # closure. Fetch counters persist across runs.
    def inline_closure(root_url: str) -> list[str] {
        if root_url not in self.pool.sheets {
            raise KeyError(root_url);
        }
        self.pool.wire_pending();
        self.seen = {};  # visited-set is per-run; counters are not
        self.spent = 0;
        rn = self.pool.sheets[root_url];
        rn spawn InlineWalk(inliner=self, depth_left=self.max_depth);
        out: set[str] = set(self.seen.keys());
        out.discard(root_url);
        return sorted(out);
    }

    def total_bytes(root_url: str) -> int {
        total = 0;
        for u in self.inline_closure(root_url) {
            total += len(self.pool.sheets[u].body);
        }
        return total;
    }
}


test "fan-out fetches each url once" {
    p = StyleSheetPool();
    p.register("/a.css", ".a {}", ["/b.css", "/c.css"]);
    p.register("/b.css", ".b {}", ["/d.css"]);
    p.register("/c.css", ".c {}", []);
    p.register("/d.css", ".d {}", []);
    inl = Inliner(pool=p);
    assert inl.inline_closure("/a.css") == ["/b.css", "/c.css", "/d.css"];
    assert p.fetch_count("/a.css") == 1;
    assert p.fetch_count("/b.css") == 1;
    assert p.fetch_count("/d.css") == 1;
    assert inl.total_bytes("/a.css") == 15;
}

test "repeat import of same url fetched once" {
    p = StyleSheetPool();
    p.register("/hub.css", ".hub {}", ["/leaf.css", "/leaf.css", "/hub2.css"]);
    p.register("/hub2.css", "", ["/leaf.css", "/leaf.css"]);
    p.register("/leaf.css", ".leaf {}", []);
    inl = Inliner(pool=p);
    assert inl.inline_closure("/hub.css") == ["/hub2.css", "/leaf.css"];
    assert p.fetch_count("/leaf.css") == 1;
}

test "import cycle terminates via visited set" {
    p = StyleSheetPool();
    p.register("/ca.css", "", ["/cb.css"]);
    p.register("/cb.css", "", ["/ca.css"]);
    inl = Inliner(pool=p);
    assert inl.inline_closure("/ca.css") == ["/cb.css"];
}

test "depth cap stops BEFORE fetching at max depth" {
    p = StyleSheetPool();
    p.register("/deep9.css", ".x {}", []);
    for i in range(8, -1, -1) {
        p.register("/deep{}.css".format(i), ".x {}", ["/deep{}.css".format(i + 1)]);
    }
    inl = Inliner(pool=p);
    closure = inl.inline_closure("/deep0.css");
    # source: depths 0..3 fetched, node AT depth == max_depth never fetched
    assert closure == ["/deep1.css", "/deep2.css", "/deep3.css"], closure;

    for i in range(10) {
        p.register("/s{}.css".format(i), "", ["/s{}.css".format(i + 1)]);
    }
    inl2 = Inliner(pool=p, max_depth=10, max_fetches=3);
    try {
        inl2.inline_closure("/s0.css");
        assert False, "expected budget error";
    } except BudgetExceeded {
        assert True;
    }
}

test "budget error is a RuntimeError family raise" {
    p = StyleSheetPool();
    p.register("/t0.css", "", ["/t1.css"]);
    p.register("/t1.css", "", []);
    inl = Inliner(pool=p, max_fetches=1);
    try {
        inl.inline_closure("/t0.css");
        assert False, "expected budget error";
    } except RuntimeError {
        assert True;
    }
}

test "public fetch increments persistent counters" {
    p = StyleSheetPool();
    p.register("/f0.css", "body0 {}", ["/f1.css"]);
    p.register("/f1.css", "body1 {}", []);
    meta = p.fetch("/f0.css");
    assert meta["body"] == "body0 {}";
    assert meta["imports"] == ["/f1.css"];
    assert p.fetch_count("/f0.css") == 1;
    p.fetch("/f0.css");
    assert p.fetch_count("/f0.css") == 2;
    assert p.fetch_count("/never.css") == 0;

    # counters persist across inline_closure runs (never cleared)
    inl = Inliner(pool=p);
    inl.inline_closure("/f0.css");
    inl.inline_closure("/f0.css");
    assert p.fetch_count("/f0.css") == 4, p.fetch_count("/f0.css");
    assert p.fetch_count("/f1.css") == 2;
}

test "duplicate registration overwrites silently" {
    p = StyleSheetPool();
    p.register("/x.css", "v1 {}", ["/y.css"]);
    p.register("/y.css", "", []);
    inl = Inliner(pool=p);
    assert inl.inline_closure("/x.css") == ["/y.css"];
    # re-register with new body and NO imports: overwrite wins, no error
    p.register("/x.css", "v2 {}", []);
    assert inl.inline_closure("/x.css") == [];
    assert inl.total_bytes("/x.css") == 0;
    assert p.fetch_count("/x.css") == 3;
}

test "unknown url fails closed" {
    p = StyleSheetPool();
    inl = Inliner(pool=p);
    try {
        inl.inline_closure("/ghost.css");
        assert False;
    } except KeyError {
        assert True;
    }
    try {
        p.fetch("/ghost.css");
        assert False;
    } except KeyError {
        assert True;
    }
}
