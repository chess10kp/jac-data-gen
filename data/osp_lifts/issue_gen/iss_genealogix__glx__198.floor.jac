"""genealogix/glx#198 — Genealogy relationship path and ancestor queries."""
import from __future__ { annotations }
import from collections { deque }
class ArchiveStore {
    def init(self: ArchiveStore) -> None {
        self._people: set[str] = `set();
        self._parents: dict[(str, list[str])] = {};
    }
}
def load_archive(
    person_ids: list[str], parent_edges: list[tuple[(str, str)]]
) -> ArchiveStore {
    arch = ArchiveStore();
    for pid in person_ids {
        arch._people.add(pid);
        arch._parents.setdefault(pid, []);
    }
    for (parent, child) in parent_edges {
        if ((parent in arch._people) and (child in arch._people)) {
            if (parent not in arch._parents[child]) {
                arch._parents[child].append(parent);
            }
        }
    }
    return arch;
}
def shortest_path(store: ArchiveStore, a: str, b: str) -> (list[str] | None) {
    if ((a not in store._people) or (b not in store._people)) {
        return None;
    }
    if (a == b) {
        return [a];
    }
    adj: dict[(str, list[str])] = {p: [] for p in store._people};
    for (child, parents) in store._parents.items() {
        for par in parents {
            adj[child].append(par);
            adj[par].append(child);
        }
    }
    seen: set[str] = {a};
    queue: deque[tuple[(str, list[str])]] = deque([(a, [a])]);
    while queue {
        (cur, path) = queue.popleft();
        for nxt in adj.get(cur, []) {
            if (nxt == b) {
                return (path + [b]);
            }
            if (nxt not in seen) {
                seen.add(nxt);
                queue.append((nxt, (path + [nxt])));
            }
        }
    }
    return None;
}
def ancestors(store: ArchiveStore, person: str, limit: int) -> list[str] {
    if (person not in store._people) {
        return [];
    }
    result: set[str] = `set();
    frontier: deque[tuple[(str, int)]] = deque([(person, 0)]);
    visited: set[str] = {person};
    while frontier {
        (cur, depth) = frontier.popleft();
        if (depth >= limit) {
            continue;
        }
        for par in store._parents.get(cur, []) {
            if (par not in visited) {
                visited.add(par);
                result.add(par);
                frontier.append((par, (depth + 1)));
            }
        }
    }
    return sorted(result);
}

