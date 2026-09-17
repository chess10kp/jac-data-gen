# Mutually Recursive Modules — dependency graph with cycle detection.
# Domain: haskellfoundation/haskell-2010-revised-report#52
# Model a module system where modules may import each other (mutual
# recursion). Provide reachability, cycle-membership, and a compile
# order that tolerates cycles by emitting strongly-connected groups.

node Module {
    has mid: str;
    has compiled: bool = False;
}

edge imports {}

obj ModuleGraph {
    has by_id: dict[str, Module] = {};

    def add_module(mid: str) -> Module {
        if mid in self.by_id {
            return self.by_id[mid];
        }
        m: Module = Module(mid=mid);
        root ++> m;
        self.by_id[mid] = m;
        return m;
    }

    def add_import(src: str, dst: str) -> bool {
        s: Module | None = self.by_id.get(src);
        d: Module | None = self.by_id.get(dst);
        if s is None or d is None {
            return False;
        }
        s +>:imports:+> d;
        return True;
    }

    def reachable(src: str) -> list[str] {
        out: list[str] = [];
        if src not in self.by_id {
            return out;
        }
        start: Module = self.by_id[src];
        seen: dict[str, bool] = {};
        frontier: list[Module] = [start];
        seen[src] = True;
        while len(frontier) > 0 {
            cur: Module = frontier.pop();
            if cur.mid != src {
                out.append(cur.mid);
            }
            for nxt in [cur ->:imports:->][?:Module] {
                if nxt.mid not in seen {
                    seen[nxt.mid] = True;
                    frontier.append(nxt);
                }
            }
        }
        return sorted(out);
    }

    def cycle_members(mid: str) -> list[str] {
        if mid not in self.by_id {
            return [];
        }
        fwd: list[str] = self.reachable(mid);
        members: list[str] = [mid];
        for other in fwd {
            back: list[str] = self.reachable(other);
            if mid in back {
                members.append(other);
            }
        }
        return sorted(members);
    }

    def in_cycle(mid: str) -> bool {
        mem: list[str] = self.cycle_members(mid);
        return len(mem) > 1;
    }

    def compile_order(mids: list[str]) -> list[str] {
        # emit acyclic modules first, then cycle groups (need joint compilation)
        simple: list[str] = [];
        cyclic: list[str] = [];
        for m in sorted(mids) {
            if m not in self.by_id {
                continue;
            }
            if self.in_cycle(m) {
                cyclic.append(m);
            } else {
                simple.append(m);
            }
        }
        out: list[str] = simple + cyclic;
        return out;
    }
}

walker InspectCycle {
    has target: str = "";
    has found: list[str] = [];

    can step with Module entry {
        if here.mid in self.found {
            skip;
        }
        self.found.append(here.mid);
        visit [here ->:imports:->];
    }
}

def probe_cycle(g: ModuleGraph, target: str) -> list[str] {
    if target not in g.by_id {
        return [];
    }
    w = g.by_id[target] spawn InspectCycle(target=target, found=[]);
    return sorted(w.found);
}

test "diamond_adversarial_revisit" {
    g = ModuleGraph();
    m_a = g.add_module("A");
    m_b = g.add_module("B");
    m_c = g.add_module("C");
    m_d = g.add_module("D");
    g.add_import("A", "B");
    g.add_import("A", "C");
    g.add_import("B", "D");
    g.add_import("C", "D");
    assert g.reachable("A") == ["B", "C", "D"];
    assert g.cycle_members("D") == ["D"];
    w = m_a spawn InspectCycle(target="A", found=[]);
    assert sorted(w.found) == ["A", "B", "C", "D"];
}

test "mutual_recursion_detected" {
    g = ModuleGraph();
    g.add_module("M");
    g.add_module("N");
    g.add_import("M", "N");
    g.add_import("N", "M");
    assert g.in_cycle("M");
    assert g.in_cycle("N");
    assert g.cycle_members("M") == ["M", "N"];
}

test "unknown_id_tolerance" {
    g = ModuleGraph();
    g.add_module("X");
    assert g.reachable("ZZZ") == [];
    assert g.cycle_members("ZZZ") == [];
    assert g.in_cycle("ZZZ") == False;
    assert g.compile_order(["ZZZ", "X"]) == ["X"];
    assert probe_cycle(g, "ZZZ") == [];
}

test "compile_order_and_add_tolerance" {
    g = ModuleGraph();
    g.add_module("A");
    g.add_module("B");
    g.add_module("C");
    g.add_module("D");
    g.add_import("A", "B");
    g.add_import("B", "A");
    g.add_import("C", "D");
    assert g.add_import("A", "NOPE") == False;
    assert g.compile_order(["C", "B", "A", "D"]) == ["C", "D", "A", "B"];
}
