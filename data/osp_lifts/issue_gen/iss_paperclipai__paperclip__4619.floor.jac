"""Issue dependency board: blocked-chain resolution over a blocks graph.

paperclipai/paperclip#4619: firstBlockedChainFinding recursively traverses
the issue dependency graph to resolve blocked chains, but had no cycle
guard -- a circular A-blocks-B-blocks-A dependency recursed until the
process died. The corrected in-memory core below keeps the hand-rolled
machinery (id-keyed state maps plus an explicit stack walk with a visited
set) and terminates on cycles instead of overflowing.
"""
class IssueBoard {
    def init(self: IssueBoard) -> object {
        self.title = {};
        self.state = {};
        self.blocks = [];
    }
    def add_issue(
        self: IssueBoard, iid: Any, title: Any, state: Any = "open"
    ) -> object {
        if (iid in self.title) {
            raise ValueError("duplicate");
        }
        if (state not in ("open", "blocked", "done")) {
            raise ValueError(state);
        }
        self.title[iid] = title;
        self.state[iid] = state;
    }
    def add_blocks(self: IssueBoard, blocker: Any, blocked: Any) -> object {
        for i in (blocker, blocked) {
            if (i not in self.title) {
                raise KeyError(i);
            }
        }
        self.blocks.append((blocker, blocked));
    }
    """Issues directly blocked by iid (rescans the edge table)."""
    def blocked_by(self: IssueBoard, iid: Any) -> list {
        return sorted(
            b
            for (a, b) in self.blocks
            if (a == iid)
        );
    }
    def blockers_of(self: IssueBoard, iid: Any) -> object {
        return sorted(
            a
            for (a, b) in self.blocks
            if (b == iid)
        );
    }
    def _closure(self: IssueBoard, start: Any) -> object {
        seen = `set();
        stack = [start];
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            stack.extend(self.blocked_by(cur));
        }
        return seen;
    }
    """Chain from iid until an issue that blocks nothing.

        On a cycle the chain stops at the first repeat and the repeated id
        is not appended twice.
        """
    def first_blocked_chain(self: IssueBoard, iid: Any) -> object {
        chain = [];
        seen = `set();
        cur = iid;
        while True {
            if (cur in seen) {
                break;
            }
            seen.add(cur);
            chain.append(cur);
            nxt = self.blocked_by(cur);
            if not nxt {
                break;
            }
            cur = nxt[0];
        }
        return chain;
    }

    """Sorted open issues transitively blocked by iid."""
    def unblockable(self: IssueBoard, iid: Any) -> object {
        return sorted(
            x
            for x in self._closure(iid)
            if (self.state[x] == "open")
        );
    }
}

