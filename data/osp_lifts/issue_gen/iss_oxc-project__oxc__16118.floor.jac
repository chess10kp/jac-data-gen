"""oxc-project/oxc#16118 — Recursive linter fix loop until stable state."""
import from __future__ { annotations }
import from collections { deque }
class LintStore {
    def init(self: LintStore) -> None {
        self._rules: set[str] = `set();
        self._triggers: dict[(str, list[str])] = {};
        self._pending: dict[(str, bool)] = {};
    }
}
def load_linter(
    rule_names: list[str],
    trigger_edges: list[tuple[(str, str)]],
    initial_pending: (list[str] | None) = None
) -> LintStore {
    store = LintStore();
    for rule in rule_names {
        store._rules.add(rule);
        store._triggers.setdefault(rule, []);
        store._pending[rule] = False;
    }
    for (src, dst) in trigger_edges {
        if ((src in store._rules) and (dst in store._rules)) {
            store._triggers.setdefault(src, []).append(dst);
        }
    }
    if initial_pending {
        for rule in initial_pending {
            if (rule in store._rules) {
                store._pending[rule] = True;
            }
        }
    }
    return store;
}
def apply_fix_round(store: LintStore) -> list[str] {
    applied: list[str] = [];
    for rule in sorted(store._rules) {
        if store._pending.get(rule) {
            applied.append(rule);
            store._pending[rule] = False;
            for nxt in store._triggers.get(rule, []) {
                store._pending[nxt] = True;
            }
        }
    }
    return applied;
}
def fix_until_stable(store: LintStore, max_rounds: int = 10) -> list[list[str]] {
    rounds: list[list[str]] = [];
    for _ in range(max_rounds) {
        batch = apply_fix_round(store);
        if not batch {
            break;
        }
        rounds.append(batch);
    }
    return rounds;
}
def reachable_rules(store: LintStore, seed: str) -> list[str] {
    if (seed not in store._rules) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([seed]);
    while queue {
        cur = queue.popleft();
        for nxt in store._triggers.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                queue.append(nxt);
            }
        }
    }
    return sorted(seen);
}

