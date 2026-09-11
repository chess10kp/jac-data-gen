"""TheLarkInn/aipm#1297 — build-unit dependency graph reachability and duplicate lineage."""

from collections import deque
from typing import Dict, List, Set, Tuple

UnitId = str
Edge = Tuple[UnitId, UnitId]


class BuildGraphError(ValueError):
    pass


class BuildPerformanceGraph:
    def __init__(self) -> None:
        self._units: Dict[UnitId, float] = {}
        self._forward: Dict[UnitId, List[UnitId]] = {}
        self._backward: Dict[UnitId, List[UnitId]] = {}

    def add_unit(self, unit_id: UnitId, compile_seconds: float) -> None:
        self._units[unit_id] = compile_seconds
        self._forward.setdefault(unit_id, [])
        self._backward.setdefault(unit_id, [])

    def add_dependency(self, from_unit: UnitId, to_unit: UnitId) -> None:
        if from_unit not in self._units or to_unit not in self._units:
            raise BuildGraphError("unknown unit")
        self._forward[from_unit].append(to_unit)
        self._backward.setdefault(to_unit, []).append(from_unit)

    def reachable_from(self, root: UnitId) -> List[UnitId]:
        if root not in self._units:
            raise BuildGraphError("unknown unit")
        seen: Set[UnitId] = set()
        queue: deque[UnitId] = deque([root])
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for nxt in sorted(self._forward.get(cur, [])):
                if nxt not in seen:
                    queue.append(nxt)
        return sorted(seen)

    def critical_path_units(self, top_n: int = 5) -> List[Tuple[UnitId, float]]:
        ranked = sorted(self._units.items(), key=lambda kv: (-kv[1], kv[0]))
        return ranked[:top_n]

    def duplicate_lineages(self, crate_versions: Dict[str, List[str]]) -> Dict[str, List[str]]:
        # Map each version token to roots that transitively depend on it
        out: Dict[str, List[str]] = {}
        for crate, versions in sorted(crate_versions.items()):
            if len(versions) < 2:
                continue
            roots = sorted(v for v in self._units if not self._backward.get(v))
            hits: List[str] = []
            for root in roots:
                reach = set(self.reachable_from(root))
                present = [ver for ver in sorted(versions) if ver in reach]
                if len(present) >= 2:
                    hits.append(root)
            if hits:
                out[crate] = hits
        return out

    def path_exists(self, source: UnitId, target: UnitId) -> bool:
        if source not in self._units or target not in self._units:
            raise BuildGraphError("unknown unit")
        seen: Set[UnitId] = set()
        stack: List[UnitId] = [source]
        while stack:
            cur = stack.pop()
            if cur == target:
                return True
            if cur in seen:
                continue
            seen.add(cur)
            stack.extend(reversed(sorted(self._forward.get(cur, []))))
        return False

    def wall_clock_share(self, units: List[UnitId]) -> float:
        total = sum(self._units.values())
        if total <= 0:
            return 0.0
        picked = sum(self._units[u] for u in units if u in self._units)
        return round(picked / total, 4)
