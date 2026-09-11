"""WillSmithTE/intlayer#1 — entrypoint dependency reachability for runtime/dev separation."""

from collections import deque
from typing import Dict, List, Set, Tuple

EntryId = str
Layer = str  # "runtime" | "server" | "dev" | "cli"


class IntlayerGraphError(ValueError):
    pass


class EntrypointGraph:
    def __init__(self) -> None:
        self._layers: Dict[EntryId, Layer] = {}
        self._forward: Dict[EntryId, List[EntryId]] = {}
        self._weight_kb: Dict[EntryId, int] = {}

    def register(self, entry_id: EntryId, layer: Layer, weight_kb: int) -> None:
        if layer not in ("runtime", "server", "dev", "cli"):
            raise IntlayerGraphError("invalid layer")
        self._layers[entry_id] = layer
        self._weight_kb[entry_id] = weight_kb
        self._forward.setdefault(entry_id, [])

    def link(self, source: EntryId, target: EntryId) -> None:
        if source not in self._layers or target not in self._layers:
            raise IntlayerGraphError("unknown entry")
        self._forward[source].append(target)

    def reachable_modules(self, root: EntryId) -> List[EntryId]:
        if root not in self._layers:
            raise IntlayerGraphError("unknown entry")
        seen: Set[EntryId] = set()
        queue: deque[EntryId] = deque([root])
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for nxt in sorted(self._forward.get(cur, [])):
                if nxt not in seen:
                    queue.append(nxt)
        return sorted(seen)

    def reachable_weight_kb(self, root: EntryId) -> int:
        mods = self.reachable_modules(root)
        return sum(self._weight_kb[m] for m in mods)

    def dev_leakage(self, root: EntryId) -> List[EntryId]:
        leaked = [
            m
            for m in self.reachable_modules(root)
            if self._layers[m] in ("dev", "cli")
        ]
        return sorted(leaked)

    def separation_report(self, roots: List[EntryId]) -> Dict[EntryId, Tuple[int, List[EntryId]]]:
        report: Dict[EntryId, Tuple[int, List[EntryId]]] = {}
        for root in sorted(roots):
            if root not in self._layers:
                raise IntlayerGraphError("unknown entry")
            report[root] = (self.reachable_weight_kb(root), self.dev_leakage(root))
        return report

    def would_isolate(self, root: EntryId, cut_edges: List[Tuple[EntryId, EntryId]]) -> int:
        # Simulate edge removal then measure reachable weight
        saved: Dict[EntryId, List[EntryId]] = {k: list(v) for k, v in self._forward.items()}
        for src, dst in cut_edges:
            if src in self._forward and dst in self._forward[src]:
                self._forward[src] = [x for x in self._forward[src] if x != dst]
        weight = self.reachable_weight_kb(root)
        self._forward = saved
        return weight
