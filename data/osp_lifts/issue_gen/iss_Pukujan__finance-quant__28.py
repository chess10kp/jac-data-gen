"""Hand-rolled implementation for Pukujan/finance-quant#28."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field


@dataclass
class Component:
    cid: str
    lane: str
    spec_hash: str
    input_hash: str
    artifact_hash: str


@dataclass
class Artifact:
    aid: str
    payload_hash: str


@dataclass
class BuildManifest:
    mid: str
    component_ids: list[str] = field(default_factory=list)


@dataclass
class Registry:
    components: dict[str, Component] = field(default_factory=dict)
    artifacts: dict[str, Artifact] = field(default_factory=dict)
    manifests: dict[str, BuildManifest] = field(default_factory=dict)
    dependencies: dict[str, list[str]] = field(default_factory=dict)
    publishes: dict[str, str] = field(default_factory=dict)
    uses: dict[str, list[str]] = field(default_factory=dict)


def new_registry() -> Registry:
    return Registry()


def register_component(
    reg: Registry, cid: str, lane: str, spec_hash: str, input_hash: str
) -> str:
    artifact_hash = lane + ":" + spec_hash + ":" + input_hash
    component = Component(cid, lane, spec_hash, input_hash, artifact_hash)
    reg.components[cid] = component
    reg.dependencies.setdefault(cid, [])
    if artifact_hash not in reg.artifacts:
        reg.artifacts[artifact_hash] = Artifact(artifact_hash, artifact_hash)
    reg.publishes[cid] = artifact_hash
    return artifact_hash


def request_artifact(
    reg: Registry, cid: str, lane: str, spec_hash: str, input_hash: str
) -> str:
    if cid in reg.components:
        current = reg.components[cid]
        if (
            current.lane == lane
            and current.spec_hash == spec_hash
            and current.input_hash == input_hash
        ):
            return current.artifact_hash
    return register_component(reg, cid, lane, spec_hash, input_hash)


def add_dependency(reg: Registry, parent_id: str, child_id: str) -> bool:
    if parent_id not in reg.components or child_id not in reg.components:
        return False
    children = reg.dependencies.setdefault(parent_id, [])
    if child_id not in children:
        children.append(child_id)
    return True


def descendants(reg: Registry, start_id: str) -> list[str]:
    if start_id not in reg.components:
        return []
    found: list[str] = []
    claimed: set[str] = set()
    pending: deque[str] = deque([start_id])
    while pending:
        current = pending.pop()
        if current in claimed:
            continue
        claimed.add(current)
        found.append(current)
        children = reg.dependencies.get(current, [])
        for child_id in reversed(children):
            pending.append(child_id)
    return found


def invalidation_plan(reg: Registry, changed_id: str) -> list[str]:
    affected = descendants(reg, changed_id)
    if affected:
        affected = affected[1:]
    return sorted(affected)


def build_manifest(reg: Registry, component_ids: list[str]) -> str:
    ids = sorted(component_ids)
    manifest_hash = "manifest"
    for cid in ids:
        if cid in reg.components:
            manifest_hash += ":" + reg.components[cid].artifact_hash
    if manifest_hash not in reg.manifests:
        reg.manifests[manifest_hash] = BuildManifest(manifest_hash, ids)
        reg.uses[manifest_hash] = []
        for cid in ids:
            if cid in reg.components:
                reg.uses[manifest_hash].append(cid)
    return manifest_hash


def cache_lookup(reg: Registry, artifact_hash: str) -> bool:
    return artifact_hash in reg.artifacts
