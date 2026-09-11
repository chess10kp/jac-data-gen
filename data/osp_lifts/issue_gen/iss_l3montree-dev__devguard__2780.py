"""l3montree-dev/devguard#2780 — content-addressed Merkle SBOM dependency store."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple

ROOT = "ROOT"


class MerkleStore:
  def __init__(self) -> None:
    self._names: Dict[str, str] = {}
    self._children: Dict[str, List[str]] = {}
    self._edges: Set[Tuple[str, str, str]] = set()
    self._hash_cache: Dict[str, str] = {}
    self._sources: Dict[Tuple[str, str, str], str] = {}
    self._source_root_hash: Dict[Tuple[str, str, str], str] = {}


def _fold_hash(component_id: str, child_hashes: List[str]) -> str:
  h = 0
  for ch in component_id:
    h = (h * 31 + ord(ch)) & 0xFFFFFFFF
  for chh in sorted(child_hashes):
    h = (h * 31 + int(chh)) & 0xFFFFFFFF
  return str(h)


def _compute_hash(store: MerkleStore, purl: str, visiting: Set[str]) -> str:
  if purl in visiting:
    return store._hash_cache.get(purl, "")
  if purl in store._hash_cache:
    return store._hash_cache[purl]
  visiting.add(purl)
  child_hashes = [
    _compute_hash(store, ch, visiting)
    for ch in sorted(store._children.get(purl, []))
  ]
  visiting.remove(purl)
  h = _fold_hash(purl, child_hashes)
  store._hash_cache[purl] = h
  return h


def load_sbom(
  components: List[Tuple[str, str]],
  deps: List[Tuple[str, str]],
  sources: List[Tuple[str, str, str, str]],
) -> MerkleStore:
  store = MerkleStore()
  for purl, name in components:
    store._names[purl] = name
    store._children.setdefault(purl, [])
  for parent, child in deps:
    if parent in store._names and child in store._names:
      store._children[parent].append(child)
  for asset_id, version, origin, root_purl in sources:
    store._sources[(asset_id, version, origin)] = root_purl
  return store


def subtree_hash(store: MerkleStore, purl: str) -> str:
  if purl not in store._names:
    return ""
  if purl in store._hash_cache:
    return store._hash_cache[purl]
  return _compute_hash(store, purl, set())


def ingest_edges(store: MerkleStore) -> int:
  before = len(store._edges)
  visiting: Set[str] = set()
  for purl in store._names:
    _compute_hash(store, purl, visiting)
  for purl in sorted(store._names):
    th = store._hash_cache[purl]
    for ch in store._children.get(purl, []):
      store._edges.add((th, purl, store._hash_cache[ch]))
  root_h = store._hash_cache.get(ROOT, "")
  for key in store._sources:
    store._source_root_hash[key] = root_h
  return len(store._edges) - before


def transitive_deps(
  store: MerkleStore, asset_id: str, version: str, origin: str,
) -> List[str]:
  key = (asset_id, version, origin)
  if key not in store._sources:
    return []
  start = store._sources[key]
  seen: Set[str] = set()
  out: List[str] = []
  queue: deque[str] = deque([start])
  while queue:
    cur = queue.popleft()
    if cur in seen:
      continue
    seen.add(cur)
    out.append(cur)
    for ch in store._children.get(cur, []):
      if ch not in seen:
        queue.append(ch)
  return sorted(out)


def _walk_up(store: MerkleStore, cur_hash: str, claimed: Set[str]) -> List[str]:
  if cur_hash in claimed:
    return []
  claimed.add(cur_hash)
  roots: List[str] = []
  for st, comp, dep_h in store._edges:
    if dep_h == cur_hash:
      if comp == ROOT:
        roots.append(st)
      else:
        roots.extend(_walk_up(store, st, claimed))
  return roots


def artifacts_with_component(store: MerkleStore, purl: str) -> List[Tuple[str, str, str]]:
  if purl not in store._names:
    return []
  seeds: List[str] = []
  for _st, comp, dep_h in store._edges:
    if comp == purl:
      seeds.append(dep_h)
  purl_h = store._hash_cache.get(purl, "")
  if not purl_h:
    purl_h = subtree_hash(store, purl)
  if purl_h and purl_h not in seeds:
    seeds.append(purl_h)
  claimed: Set[str] = set()
  root_hashes: List[str] = []
  for sh in seeds:
    for rh in _walk_up(store, sh, claimed):
      if rh not in root_hashes:
        root_hashes.append(rh)
  out: List[Tuple[str, str, str]] = []
  for key, rh in store._source_root_hash.items():
    if rh in root_hashes:
      out.append(key)
  return sorted(out)
