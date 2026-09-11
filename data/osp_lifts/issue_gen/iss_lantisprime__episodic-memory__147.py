"""lantisprime/episodic-memory#147 — triggered_by cycle detection."""

class TriggerGraph:
    """Adjacency dict + DFS path stack for trigger cycles."""

    def __init__(self) -> None:
        self._adj: dict[str, list[str]] = {}
        self._nodes: set[str] = set()

    def add_trigger(self, source: str, target: str) -> None:
        self._nodes.add(source)
        self._nodes.add(target)
        self._adj.setdefault(source, [])
        if target not in self._adj[source]:
            self._adj[source].append(target)

    def find_cycles(self) -> list[list[str]]:
        cycles: list[list[str]] = []
        visited: set[str] = set()
        stack: list[str] = []
        on_stack: set[str] = set()

        def dfs(node: str) -> None:
            visited.add(node)
            on_stack.add(node)
            stack.append(node)
            for nxt in self._adj.get(node, []):
                if nxt not in visited:
                    dfs(nxt)
                elif nxt in on_stack:
                    idx = stack.index(nxt)
                    cycle = stack[idx:] + [nxt]
                    norm = cycle[:-1]
                    if norm not in cycles:
                        cycles.append(norm)
            stack.pop()
            on_stack.remove(node)

        for n in sorted(self._nodes):
            if n not in visited:
                dfs(n)
        return sorted(cycles, key=lambda c: (len(c), c))

    def would_create_cycle(self, source: str, target: str) -> bool:
        if source == target:
            return True
        seen: set[str] = set()
        stack: list[str] = [target]
        while stack:
            cur = stack.pop()
            if cur == source:
                return True
            if cur in seen:
                continue
            seen.add(cur)
            stack.extend(self._adj.get(cur, []))
        return False

    def reachable_from(self, start: str) -> list[str]:
        if start not in self._nodes:
            return []
        seen: set[str] = set()
        stack: list[str] = [start]
        out: list[str] = []
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            if cur != start:
                out.append(cur)
            stack.extend(self._adj.get(cur, []))
        return sorted(out)
