"""BootBlock/Gubbins#403 — backlog triage parent-issue chain for effective tier."""
import from __future__ { annotations }
class BacklogRegistry {
    def init(self: BacklogRegistry) -> None {
        self._parent_of: dict[(str, (str | None))] = {};
        self._tier_of: dict[(str, int)] = {};
    }
}
def load_backlog(issues: list[tuple[(str, int, (str | None))]]) -> BacklogRegistry {
    reg = BacklogRegistry();
    for (iid, tier, parent) in issues {
        if ((parent is not None) and (parent not in reg._tier_of)) {
            raise KeyError("unknown parent issue");
        }
        reg._parent_of[iid] = parent;
        reg._tier_of[iid] = tier;
    }
    return reg;
}
def _chain(reg: BacklogRegistry, issue_id: str) -> list[str] {
    if (issue_id not in reg._tier_of) {
        return [];
    }
    chain: list[str] = [];
    cur: (str | None) = issue_id;
    seen: set[str] = set();
    while (cur is not None) {
        if (cur in seen) {
            break;
        }
        seen.add(cur);
        chain.append(cur);
        cur = reg._parent_of.get(cur);
    }
    return chain;
}
def ancestor_issues(reg: BacklogRegistry, issue_id: str) -> list[str] {
    chain = _chain(reg, issue_id);
    rev: list[str] = [];
    for i in range((len(chain) - 1), -1, -1) {
        rev.append(chain[i]);
    }
    return rev;
}
def effective_tier(reg: BacklogRegistry, issue_id: str) -> int {
    chain = _chain(reg, issue_id);
    if not chain {
        return 99;
    }
    best = reg._tier_of[chain[0]];
    for iid in chain {
        t = reg._tier_of.get(iid, 99);
        if (t < best) {
            best = t;
        }
    }
    return best;
}
def subtree_issues(reg: BacklogRegistry, `root: str) -> list[str] {
    if (`root not in reg._tier_of) {
        return [];
    }
    children: dict[(str, list[str])] = {};
    for (iid, parent) in reg._parent_of.items() {
        if (parent is not None) {
            children.setdefault(parent, []).append(iid);
        }
    }
    seen: set[str] = set();
    stack = [`root];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for ch in sorted(children.get(cur, [])) {
            stack.append(ch);
        }
    }
    return sorted(seen);
}

