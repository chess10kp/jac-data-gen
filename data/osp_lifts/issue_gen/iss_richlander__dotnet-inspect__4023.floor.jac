"""richlander/dotnet-inspect#4023 — Bounded call-graph overlay for annotated source."""
import from __future__ { annotations }
import from collections { deque }
class CallOverlayStore {
    def init(self: CallOverlayStore) -> None {
        self._members: set[str] = `set();
        self._calls: dict[(str, list[str])] = {};
        self._callers: dict[(str, list[str])] = {};
    }
}
def load_overlay(
    member_names: list[str], call_edges: list[tuple[(str, str)]]
) -> CallOverlayStore {
    store = CallOverlayStore();
    for name in member_names {
        store._members.add(name);
        store._calls.setdefault(name, []);
        store._callers.setdefault(name, []);
    }
    for (caller, callee) in call_edges {
        if ((caller in store._members) and (callee in store._members)) {
            store._calls.setdefault(caller, []).append(callee);
            store._callers.setdefault(callee, []).append(caller);
        }
    }
    return store;
}
def callees_within(store: CallOverlayStore, member: str, depth: int) -> list[str] {
    if ((member not in store._members) or (depth < 0)) {
        return [];
    }
    seen: set[str] = `set();
    frontier: deque[tuple[(str, int)]] = deque([(member, 0)]);
    while frontier {
        (cur, d) = frontier.popleft();
        if (d >= depth) {
            continue;
        }
        for nxt in store._calls.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                frontier.append((nxt, (d + 1)));
            }
        }
    }
    return sorted(seen);
}
def callers_within(store: CallOverlayStore, member: str, depth: int) -> list[str] {
    if ((member not in store._members) or (depth < 0)) {
        return [];
    }
    seen: set[str] = `set();
    frontier: deque[tuple[(str, int)]] = deque([(member, 0)]);
    while frontier {
        (cur, d) = frontier.popleft();
        if (d >= depth) {
            continue;
        }
        for nxt in store._callers.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                frontier.append((nxt, (d + 1)));
            }
        }
    }
    return sorted(seen);
}
def fan_in(store: CallOverlayStore, member: str) -> int {
    if (member not in store._members) {
        return 0;
    }
    return len(store._callers.get(member, []));
}

