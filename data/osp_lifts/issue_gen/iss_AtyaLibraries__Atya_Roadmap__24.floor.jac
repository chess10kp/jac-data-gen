"""AtyaLibraries/Atya.Roadmap#24 — Fleet manifest dependency audit walk."""
import from __future__ { annotations }
import from collections { deque }
class FleetManifest {
    def init(self: FleetManifest) -> None {
        self._repos: set[str] = `set();
        self._refs: dict[(str, list[str])] = {};
    }
}
def load_fleet_manifest(
    repos: list[str], refs: list[tuple[(str, str)]]
) -> FleetManifest {
    m = FleetManifest();
    for r in repos {
        m._repos.add(r);
        m._refs.setdefault(r, []);
    }
    for (src, dst) in refs {
        if ((src in m._repos) and (dst in m._repos)) {
            m._refs.setdefault(src, []).append(dst);
        }
    }
    return m;
}
def reachable_repos(manifest: FleetManifest, `root: str) -> list[str] {
    if (`root not in manifest._repos) {
        return [];
    }
    seen: set[str] = {`root};
    queue: deque[str] = deque([`root]);
    while queue {
        cur = queue.popleft();
        for nxt in manifest._refs.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                queue.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def drift_violations(
    manifest: FleetManifest, actual_refs: list[tuple[(str, str)]]
) -> list[tuple[(str, str)]] {
    expected: set[tuple[(str, str)]] = `set();
    for src in manifest._repos {
        for dst in manifest._refs.get(src, []) {
            expected.add((src, dst));
        }
    }
    actual = `set(actual_refs);
    missing = expected - actual;
    extra = actual - expected;
    return sorted((missing | extra));
}
def orphan_repos(manifest: FleetManifest, roots: list[str]) -> list[str] {
    reachable: set[str] = `set();
    for r in roots {
        reachable.update(reachable_repos(manifest, r));
    }
    return sorted(
        repo
        for repo in manifest._repos
        if (repo not in reachable)
    );
}

