"""EffortlessMetrics/perl-lsp-swarm#7949 — compiler cache restart equivalence oracle."""

from __future__ import annotations

from collections import deque


class CompilerCacheWorld:
    def __init__(self) -> None:
        self.artifacts: set[str] = set()
        self.depends: dict[str, list[str]] = {}
        self.keys: dict[str, str] = {}
        self.digests: dict[str, str] = {}


def load_compiler_cache_world(
    artifacts: list[str],
    depends: list[tuple[str, str]],
    keys: dict[str, str],
    digests: dict[str, str],
) -> CompilerCacheWorld:
    w = CompilerCacheWorld()
    for art in artifacts:
        w.artifacts.add(art)
        w.depends.setdefault(art, [])
    for consumer, dep in depends:
        if consumer in w.artifacts and dep in w.artifacts:
            if dep not in w.depends[consumer]:
                w.depends[consumer].append(dep)
    w.keys = dict(keys)
    w.digests = dict(digests)
    return w


def _rev_depends(w: CompilerCacheWorld) -> dict[str, list[str]]:
    rev: dict[str, list[str]] = {}
    for consumer, deps in w.depends.items():
        for dep in deps:
            rev.setdefault(dep, []).append(consumer)
    return rev


def dependency_closure(w: CompilerCacheWorld, artifact: str) -> list[str]:
    if artifact not in w.artifacts:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([artifact])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in w.depends.get(cur, []):
            if dep not in seen:
                q.append(dep)
    return sorted(seen)


def invalidation_closure(w: CompilerCacheWorld, seeds: list[str]) -> list[str]:
    rev = _rev_depends(w)
    roots = [s for s in seeds if s in w.artifacts]
    if not roots:
        return []
    seen: set[str] = set(roots)
    q: deque[str] = deque(roots)
    while q:
        cur = q.popleft()
        for nxt in sorted(rev.get(cur, [])):
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return sorted(seen)


def checkpoint_status(
    w: CompilerCacheWorld,
    manifest_roots: list[str],
    current_keys: dict[str, str],
) -> dict[str, str]:
    needed: set[str] = set()
    for root in manifest_roots:
        needed.update(dependency_closure(w, root))
    out: dict[str, str] = {}
    for art in sorted(needed):
        if art not in w.artifacts:
            out[art] = "miss"
        elif not w.digests.get(art):
            out[art] = "quarantine"
        elif current_keys.get(art) != w.keys.get(art):
            out[art] = "recompute"
        else:
            out[art] = "adopt"
    return out


def corruption_fallback(*, decode_ok: bool, digest_ok: bool, schema_ok: bool) -> str:
    if not schema_ok:
        return "cold"
    if not decode_ok or not digest_ok:
        return "quarantine"
    return "adopt"


def provider_is_current(
    w: CompilerCacheWorld,
    provider_art: str,
    invalidated: list[str],
) -> bool:
    if provider_art not in w.artifacts:
        return False
    bad = set(invalidated)
    if provider_art in bad:
        return False
    for dep in w.depends.get(provider_art, []):
        if dep in bad:
            return False
    return True


def bust_live_cache(
    w: CompilerCacheWorld,
    seeds: list[str],
    cache: dict[str, str],
) -> list[str]:
    victims = invalidation_closure(w, seeds)
    for art in victims:
        cache.pop(art, None)
    return victims
