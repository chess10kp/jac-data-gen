"""Codra-Ingenierie-Informatique/ModuleTester#18 — Test dependency execution order."""

node TestNode {
    has name: str;
    has status: str = "pending";
}

edge DependsOn {}

obj TestGraph {
    has tests: dict[str, TestNode] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with TestNode entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for blk in [here <-:DependsOn:<-][?:TestNode] {
            if blk.name in self.stack {
                self.errors.append((blk.name, here.name));
            } else {
                if not (blk.name in self.visited) { visit [blk]; }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_test_graph(
    tests: list[str],
    deps: list[tuple[str, str]],
) -> TestGraph {
    g = TestGraph();
    for name in tests {
        nd = TestNode(name=name);
        root ++> nd;
        g.tests[name] = nd;
    }
    for (blocker, target) in deps {
        blk = g.tests.get(blocker, None);
        tgt = g.tests.get(target, None);
        if blk is not None and tgt is not None { blk +>:DependsOn:+> tgt; }
    }
    return g;
}

def runnable_tests(g: TestGraph) -> list[str] {
    ready: list[str] = [];
    for (name, nd) in g.tests.items() {
        if nd.status != "pending" { continue; }
        blocked = False;
        for blk in [nd <-:DependsOn:<-][?:TestNode] {
            if blk.status != "passed" { blocked = True; }
        }
        if not blocked { ready.append(name); }
    }
    return sorted(ready);
}

def detect_test_cycles(g: TestGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(g.tests.keys()) {
        if k in visited { continue; }
        nd = g.tests[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def mark_passed(g: TestGraph, test_name: str) {
    nd = g.tests.get(test_name, None);
    if nd is not None { nd.status = "passed"; }
}

def mark_failed(g: TestGraph, test_name: str) -> list[str] {
    nd = g.tests.get(test_name, None);
    if nd is None { return []; }
    nd.status = "failed";
    skipped: list[str] = [];
    changed = True;
    while changed {
        changed = False;
        for (name, tgt) in g.tests.items() {
            if tgt.status != "pending" { continue; }
            chain_blocked = False;
            for blk in [tgt <-:DependsOn:<-][?:TestNode] {
                if blk.status == "failed" or blk.status == "skipped" {
                    chain_blocked = True;
                }
            }
            if chain_blocked {
                tgt.status = "skipped";
                skipped.append(name);
                changed = True;
            }
        }
    }
    return sorted(skipped);
}
