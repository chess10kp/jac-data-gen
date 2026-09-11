"""Gentleman-Programming/gentle-ai#2295 — SDD workflow authority reference reachability.

verify-report metadata participates in workspace identity; stale predecessor
references create a verify-review cycle. The runtime models transitions as an
adjacency dict and walks reachable states with an explicit visited set.
"""
import from __future__ { annotations }
class Workflow {
    def init(self: Workflow) -> None {
        self.states: dict[(str, bool)] = {};
        self.next_of: dict[(str, list[str])] = {};
        self.authority_of: dict[(str, str)] = {};
    }
    def add_state(self: Workflow, name: str, authority: str) -> None {
        self.states[name] = True;
        self.next_of.setdefault(name, []);
        self.authority_of[name] = authority;
    }
    def add_transition(self: Workflow, src: str, dst: str) -> None {
        if ((src in self.states) and (dst in self.states)) {
            self.next_of[src].append(dst);
        }
    }
}
def load_workflow(
    states: list[tuple[(str, str)]], transitions: list[tuple[(str, str)]]
) -> Workflow {
    w = Workflow();
    for (name, auth) in states {
        w.add_state(name, auth);
    }
    for (src, dst) in transitions {
        w.add_transition(src, dst);
    }
    return w;
}
def reachable_states(w: Workflow, start: str) -> list[str] {
    if (start not in w.states) {
        return [];
    }
    seen: set[str] = `set();
    stack: list[str] = [start];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for nxt in w.next_of.get(cur, []) {
            if (nxt not in seen) {
                stack.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def blocks_archive(w: Workflow, report_state: str, bound_authority: str) -> bool {
    if (report_state not in w.states) {
        return False;
    }
    report_auth = w.authority_of.get(report_state, "");
    if (report_auth == bound_authority) {
        return False;
    }
    cycle = load_workflow(
        [(s, w.authority_of[s]) for s in w.states],
        [
            ("verify", "review"),
            ("review", "verify_refresh"),
            ("verify_refresh", "verify")
        ]
    );
    reach = `set(reachable_states(cycle, "verify"));
    return ((report_state in reach) and (report_auth != bound_authority));
}

