"""abdullahbodur/horo-engine#2053 — DAG/pin/cycle/limit validation with stable diagnostics."""

from collections import deque
from typing import Dict, List, Optional, Set, Tuple

NodeId = str
Pin = Tuple[str, str]  # (node_id, pin_name)
Edge = Tuple[Pin, Pin]


class GraphValidationError(ValueError):
    pass


class WorkflowValidator:
    def __init__(self) -> None:
        self._nodes: Dict[NodeId, Dict[str, str]] = {}
        self._forward: Dict[NodeId, List[Tuple[NodeId, str, str]]] = {}
        self._limits: Dict[str, int] = {}
        self._node_limits: Dict[NodeId, int] = {}

    def add_node(self, node_id: NodeId, outputs: Dict[str, str]) -> None:
        if node_id in self._nodes:
            raise GraphValidationError("duplicate node id")
        self._nodes[node_id] = dict(outputs)
        self._forward.setdefault(node_id, [])

    def add_edge(self, src: Pin, dst: Pin) -> None:
        s_node, s_pin = src
        d_node, d_pin = dst
        if s_node not in self._nodes or d_node not in self._nodes:
            raise GraphValidationError("dangling edge")
        if s_pin not in self._nodes[s_node]:
            raise GraphValidationError("incompatible pin")
        if d_pin not in self._nodes[d_node]:
            raise GraphValidationError("incompatible pin")
        if self._nodes[s_node][s_pin] != self._nodes[d_node][d_pin]:
            raise GraphValidationError("incompatible pin")
        self._forward[s_node].append((d_node, s_pin, d_pin))

    def set_graph_limit(self, name: str, max_count: int) -> None:
        self._limits[name] = max_count

    def set_node_budget(self, node_id: NodeId, max_instances: int) -> None:
        self._node_limits[node_id] = max_instances

    def detect_cycle(self) -> Optional[List[NodeId]]:
        indeg: Dict[NodeId, int] = {n: 0 for n in self._nodes}
        for src, outs in self._forward.items():
            for dst, _, _ in outs:
                indeg[dst] = indeg.get(dst, 0) + 1
        queue: deque[NodeId] = deque(sorted(n for n, d in indeg.items() if d == 0))
        seen = 0
        order: List[NodeId] = []
        indeg_work = dict(indeg)
        while queue:
            n = queue.popleft()
            order.append(n)
            seen += 1
            for dst, _, _ in sorted(self._forward.get(n, []), key=lambda x: x[0]):
                indeg_work[dst] -= 1
                if indeg_work[dst] == 0:
                    queue.append(dst)
        if seen == len(indeg):
            return None
        # extract cycle via DFS parent trail
        parent: Dict[NodeId, Optional[NodeId]] = {n: None for n in self._nodes}
        stack: Set[NodeId] = set()
        cycle: List[NodeId] = []

        def dfs(u: NodeId) -> bool:
            stack.add(u)
            for v, _, _ in sorted(self._forward.get(u, []), key=lambda x: x[0]):
                if v not in stack:
                    parent[v] = u
                    if dfs(v):
                        return True
                else:
                    cur = u
                    chain = [v]
                    while cur != v and cur is not None:
                        chain.append(cur)
                        cur = parent.get(cur)
                    cycle.extend(reversed(chain))
                    return True
            stack.remove(u)
            return False

        for start in sorted(self._nodes):
            if dfs(start):
                break
        return cycle or sorted(self._nodes)

    def validate(self) -> List[str]:
        diags: List[str] = []
        if len(self._nodes) > self._limits.get("nodes", 10**9):
            diags.append("limit:nodes exceeded")
        for nid, cap in sorted(self._node_limits.items()):
            if cap < 0:
                diags.append(f"limit:node:{nid} invalid")
        cyc = self.detect_cycle()
        if cyc:
            diags.append("cycle:" + ">".join(cyc))
        return sorted(diags)

    def topological_order(self) -> List[NodeId]:
        if self.detect_cycle():
            raise GraphValidationError("cycle detected")
        indeg: Dict[NodeId, int] = {n: 0 for n in self._nodes}
        for src, outs in self._forward.items():
            for dst, _, _ in outs:
                indeg[dst] += 1
        queue: deque[NodeId] = deque(sorted(n for n, d in indeg.items() if d == 0))
        order: List[NodeId] = []
        while queue:
            n = queue.popleft()
            order.append(n)
            for dst, _, _ in sorted(self._forward.get(n, []), key=lambda x: x[0]):
                indeg[dst] -= 1
                if indeg[dst] == 0:
                    queue.append(dst)
        return order
