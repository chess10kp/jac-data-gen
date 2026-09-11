"""ShippedLabs/soroban-upgrade-safeguard#431 — mutually recursive UDT refs overflow compare walks.

Contract spec diff classifies findings by walking type-reference graphs.
``extract_udts`` and ``detect_cascading_layout_breaks`` guard cycles with
visited/cascaded sets, but ``references_type`` only skips a direct self-field
edge, so ``A { b: B }`` / ``B { a: A }`` makes ``is_type_used_in_functions``
recurse without bound when a function takes ``A``.
"""

from __future__ import annotations

from collections import deque


class ContractSpec:
    def __init__(self) -> None:
        self.udt_fields: dict[str, list[str]] = {}
        self.functions: dict[str, list[str]] = {}
        self.events: dict[str, list[str]] = {}


def load_spec(
    udt_fields: dict[str, list[str]],
    functions: dict[str, list[str]] | None = None,
    events: dict[str, list[str]] | None = None,
) -> ContractSpec:
    spec = ContractSpec()
    spec.udt_fields = {k: list(v) for k, v in udt_fields.items()}
    spec.functions = {k: list(v) for k, v in (functions or {}).items()}
    spec.events = {k: list(v) for k, v in (events or {}).items()}
    return spec


def extract_udts(spec: ContractSpec, root: str) -> list[str]:
    if root not in spec.udt_fields:
        return [root]
    seen: set[str] = set()
    work: deque[str] = deque([root])
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ref in sorted(spec.udt_fields.get(cur, [])):
            if ref in spec.udt_fields and ref not in seen:
                work.append(ref)
    return sorted(seen)


def references_type(spec: ContractSpec, from_type: str, target: str) -> bool:
    visited: set[str] = set()

    def walk(cur: str) -> bool:
        if cur in visited:
            return False
        visited.add(cur)
        if cur == target:
            return True
        fields = spec.udt_fields.get(cur)
        if fields is None:
            return False
        for ref in fields:
            if ref == target:
                return True
            if ref == cur:
                continue
            if walk(ref):
                return True
        return False

    if from_type not in spec.udt_fields:
        return from_type == target
    return walk(from_type)


def is_type_used_in_functions(spec: ContractSpec, type_name: str) -> bool:
    for params in spec.functions.values():
        for param in params:
            if param == type_name or references_type(spec, param, type_name):
                return True
    return False


def is_type_used_in_events(spec: ContractSpec, type_name: str) -> bool:
    for fields in spec.events.values():
        for field_type in fields:
            if field_type == type_name or references_type(spec, field_type, type_name):
                return True
    return False


def detect_cascading_layout_breaks(
    spec: ContractSpec, changed: list[str]
) -> list[str]:
    cascaded: set[str] = set()
    work: deque[str] = deque(changed)
    while work:
        cur = work.popleft()
        if cur in cascaded:
            continue
        cascaded.add(cur)
        for udt, fields in spec.udt_fields.items():
            if udt not in cascaded and cur in fields:
                work.append(udt)
    return sorted(cascaded)


def classify_finding_axes(spec: ContractSpec, finding_type: str) -> list[str]:
    axes: list[str] = []
    if is_type_used_in_functions(spec, finding_type):
        axes.append("function_usage")
    if is_type_used_in_events(spec, finding_type):
        axes.append("event_usage")
    if finding_type in detect_cascading_layout_breaks(spec, [finding_type]):
        axes.append("layout_cascade")
    return sorted(axes)
