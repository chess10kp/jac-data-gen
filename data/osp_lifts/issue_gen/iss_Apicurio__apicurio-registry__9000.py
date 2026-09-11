"""Apicurio/apicurio-registry#9000 — Reference tree resolve keyed by GAV."""

from __future__ import annotations


class RefRegistry:
    def __init__(self) -> None:
        self._content: dict[str, str] = {}
        self._refs: dict[str, list[tuple[str, str, str, str]]] = {}


def gav_key(group: str, artifact: str, version: str) -> str:
    return f"{group}:{artifact}:{version}"


def load_registry(
    artifacts: list[tuple[str, str, str, str]],
    ref_edges: list[tuple[str, str, str, str, str, str, str]],
) -> RefRegistry:
    reg = RefRegistry()
    for group, artifact, version, body in artifacts:
        reg._content[gav_key(group, artifact, version)] = body
        reg._refs.setdefault(gav_key(group, artifact, version), [])
    for (
        owner_g,
        owner_a,
        owner_v,
        ref_name,
        ref_g,
        ref_a,
        ref_v,
    ) in ref_edges:
        owner = gav_key(owner_g, owner_a, owner_v)
        reg._refs.setdefault(owner, []).append(
            (ref_name, ref_g, ref_a, ref_v)
        )
    return reg


def resolve_tree(reg: RefRegistry, root_gav: str) -> dict[str, str]:
    out: dict[str, str] = {}
    stack = [root_gav]
    visited: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in visited:
            continue
        visited.add(cur)
        body = reg._content.get(cur)
        if body is not None:
            out[cur] = body
        for _name, rg, ra, rv in reg._refs.get(cur, []):
            key = gav_key(rg, ra, rv)
            if key not in visited:
                stack.append(key)
    return out
