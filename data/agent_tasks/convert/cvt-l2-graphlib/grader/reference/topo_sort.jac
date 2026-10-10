"""Topological sorting of a graph of hashable nodes.

Port of CPython's graphlib (TopologicalSorter + CycleError).
"""

glob NODE_OUT: int = -1,
     NODE_DONE: int = -2;

"""Raised by TopologicalSorter.prepare when the graph has a cycle.

`args[1]` is the cycle: each node is an immediate predecessor of the next,
and the first and last node are the same."""
class CycleError(ValueError) {}

"""Bookkeeping for one node: how many predecessors are still pending
(or NODE_OUT / NODE_DONE once handed out / finished) and its successors."""
obj NodeInfo {
    has item: any;
    has npredecessors: int = 0;
    has successors: list[any] = [];
}

obj TopologicalSorter {
    has deps: dict[any, any] | None = None;
    has node2info: dict[any, NodeInfo] = {};
    has ready_nodes: list[any] | None = None;
    has npassedout: int = 0;
    has nfinished: int = 0;

    def postinit {
        if self.deps is not None {
            for (n, predecessors) in self.deps.items() {
                self.add(n, *predecessors);
            }
        }
    }

    def get_nodeinfo(n: any) -> NodeInfo {
        result = self.node2info.get(n);
        if result is None {
            result = NodeInfo(item=n);
            self.node2info[n] = result;
        }
        return result;
    }

    """Add a node and its predecessors; repeated calls union the dependencies."""
    def add(n: any, *predecessors: any) {
        if self.ready_nodes is not None {
            raise ValueError("Nodes cannot be added after a call to prepare()");
        }
        nodeinfo = self.get_nodeinfo(n);
        nodeinfo.npredecessors += len(predecessors);
        for pred in predecessors {
            self.get_nodeinfo(pred).successors.append(n);
        }
    }

    """Freeze the graph and check for cycles (raises CycleError)."""
    def prepare {
        if self.ready_nodes is not None {
            raise ValueError("cannot prepare() more than once");
        }
        self.ready_nodes = [i.item for i in self.node2info.values() if i.npredecessors == 0];
        cycle = self.find_cycle();
        if cycle {
            raise CycleError("nodes are in a cycle", cycle);
        }
    }

    def require_prepared -> list[any] {
        if self.ready_nodes is None {
            raise ValueError("prepare() must be called first");
        }
        return self.ready_nodes;
    }

    """All nodes that are ready now (each returned only once)."""
    def get_ready -> tuple[any, ...] {
        ready = self.require_prepared();
        result = tuple(ready);
        for n in result {
            self.node2info[n].npredecessors = NODE_OUT;
        }
        ready.clear();
        self.npassedout += len(result);
        return result;
    }

    def is_active -> bool {
        ready = self.require_prepared();
        return self.nfinished < self.npassedout or bool(ready);
    }

    def __bool__ -> bool {
        return self.is_active();
    }

    """Mark nodes returned by get_ready as processed, unblocking successors."""
    def done(*nodes: any) {
        ready = self.require_prepared();
        for n in nodes {
            nodeinfo = self.node2info.get(n);
            if nodeinfo is None {
                raise ValueError(f"node {n!r} was not added using add()");
            }
            stat = nodeinfo.npredecessors;
            if stat != NODE_OUT {
                if stat >= 0 {
                    raise ValueError(f"node {n!r} was not passed out (still not ready)");
                }
                raise ValueError(f"node {n!r} was already marked done");
            }
            nodeinfo.npredecessors = NODE_DONE;
            for successor in nodeinfo.successors {
                succ = self.node2info[successor];
                succ.npredecessors -= 1;
                if succ.npredecessors == 0 {
                    ready.append(successor);
                }
            }
            self.nfinished += 1;
        }
    }

    """Iterative DFS over successor lists; returns one cycle or None."""
    def find_cycle -> list[any] | None {
        stack: list[any] = [];
        positions: list[int] = [];
        seen: set[any] = set();
        node2stacki: dict[any, int] = {};
        for start in self.node2info {
            if start in seen {
                continue;
            }
            n = start;
            while True {
                if n in seen {
                    if n in node2stacki {
                        return stack[node2stacki[n]:] + [n];
                    }
                } else {
                    seen.add(n);
                    positions.append(0);
                    node2stacki[n] = len(stack);
                    stack.append(n);
                }
                # backtrack to the topmost stack entry with another successor
                advanced = False;
                while stack {
                    succs = self.node2info[stack[-1]].successors;
                    k = positions[-1];
                    if k < len(succs) {
                        positions[-1] = k + 1;
                        n = succs[k];
                        advanced = True;
                        break;
                    }
                    del node2stacki[stack.pop()];
                    positions.pop();
                }
                if not advanced {
                    break;
                }
            }
        }
        return None;
    }

    """Nodes in a topological order (prepares the sorter)."""
    def static_order -> list[any] {
        self.prepare();
        order: list[any] = [];
        while self.is_active() {
            group = self.get_ready();
            order.extend(group);
            self.done(*group);
        }
        return order;
    }
}
