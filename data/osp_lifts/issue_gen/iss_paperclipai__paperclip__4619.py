"""Issue dependency board: blocked-chain resolution over a blocks graph.

paperclipai/paperclip#4619: firstBlockedChainFinding recursively traverses
the issue dependency graph to resolve blocked chains, but had no cycle
guard -- a circular A-blocks-B-blocks-A dependency recursed until the
process died. The corrected in-memory core below keeps the hand-rolled
machinery (id-keyed state maps plus an explicit stack walk with a visited
set) and terminates on cycles instead of overflowing.
"""


class IssueBoard:
    def __init__(self):
        self.title = {}   # iid -> title
        self.state = {}   # iid -> "open" | "blocked" | "done"
        self.blocks = []  # (blocker, blocked)

    def add_issue(self, iid, title, state="open"):
        if iid in self.title:
            raise ValueError("duplicate")
        if state not in ("open", "blocked", "done"):
            raise ValueError(state)
        self.title[iid] = title
        self.state[iid] = state

    def add_blocks(self, blocker, blocked):
        for i in (blocker, blocked):
            if i not in self.title:
                raise KeyError(i)
        self.blocks.append((blocker, blocked))

    def blocked_by(self, iid):
        """Issues directly blocked by iid (rescans the edge table)."""
        return sorted(b for a, b in self.blocks if a == iid)

    def blockers_of(self, iid):
        return sorted(a for a, b in self.blocks if b == iid)

    def _closure(self, start):
        seen = set()
        stack = [start]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue  # cycle/diamond revisit: terminate this branch
            seen.add(cur)
            stack.extend(self.blocked_by(cur))
        return seen

    def first_blocked_chain(self, iid):
        """Chain from iid until an issue that blocks nothing.

        On a cycle the chain stops at the first repeat and the repeated id
        is not appended twice.
        """
        chain = []
        seen = set()
        cur = iid
        while True:
            if cur in seen:
                break  # cycle policy: stop at first revisit
            seen.add(cur)
            chain.append(cur)
            nxt = self.blocked_by(cur)
            if not nxt:
                break
            cur = nxt[0]
        return chain

    def unblockable(self, iid):
        """Sorted open issues transitively blocked by iid."""
        return sorted(x for x in self._closure(iid) if self.state[x] == "open")
