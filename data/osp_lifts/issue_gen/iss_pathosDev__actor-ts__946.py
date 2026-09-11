"""pathosDev/actor-ts#946 — encodeRefs/decodeRefs need ancestor-path guards, not visited sets."""

from __future__ import annotations


class RefStore:
    def __init__(self) -> None:
        self._objects: dict[str, dict] = {}
        self._actor_refs: dict[str, str] = {}


def load_ref_store(
    objects: list[tuple[str, dict]],
    actor_refs: list[tuple[str, str]] | None = None,
) -> RefStore:
    store = RefStore()
    for oid, payload in objects:
        store._objects[oid] = dict(payload)
    for name, target in actor_refs or []:
        store._actor_refs[name] = target
    return store


def _walk_encode(store: RefStore, value: object, path: set[str]) -> object:
    if value is None or isinstance(value, (int, float, bool)):
        return value
    if isinstance(value, str):
        if value.startswith("@actor:"):
            return value
        if value in store._actor_refs:
            return f"@actor:{store._actor_refs[value]}"
        if value.startswith("@obj:"):
            oid = value[5:]
            if oid not in store._objects:
                return value
            if oid in path:
                return None
            path.add(oid)
            encoded = {
                k: _walk_encode(store, v, path)
                for k, v in sorted(store._objects[oid].items())
            }
            path.remove(oid)
            return encoded
        return value
    if isinstance(value, list):
        return [_walk_encode(store, v, path) for v in value]
    if isinstance(value, dict):
        return {
            k: _walk_encode(store, v, path)
            for k, v in sorted(value.items())
        }
    return value


def encode_refs(store: RefStore, body: dict) -> dict:
    out = _walk_encode(store, body, set())
    return out if isinstance(out, dict) else {}


def _walk_decode(store: RefStore, value: object, path: set[int]) -> object:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, list):
        return [_walk_decode(store, v, path) for v in value]
    if isinstance(value, dict):
        sig = id(value)
        if sig in path:
            return None
        path.add(sig)
        decoded = {
            k: _walk_decode(store, v, path)
            for k, v in sorted(value.items())
        }
        path.remove(sig)
        return decoded
    return value


def decode_refs(store: RefStore, body: dict) -> dict:
    out = _walk_decode(store, body, set())
    return out if isinstance(out, dict) else {}


def shared_object_ids(store: RefStore, body: dict) -> list[str]:
    counts: dict[str, int] = {}

    def scan(val: object) -> None:
        if isinstance(val, str) and val.startswith("@obj:"):
            oid = val[5:]
            counts[oid] = counts.get(oid, 0) + 1
        elif isinstance(val, list):
            for item in val:
                scan(item)
        elif isinstance(val, dict):
            for item in val.values():
                scan(item)

    scan(body)
    return sorted(k for k, n in counts.items() if n > 1)
