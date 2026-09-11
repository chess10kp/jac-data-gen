"""Synthetic before-code for byjesper/laravel-decision-support#27.

RunState.has_visited() performs an O(N) linear scan over path on every call.
GuideRunner's acyclic revisit guard invokes it once per transition.
"""

node GuideNode {
    has key: str;
}

edge LeadsTo {}

def _linear_contains(path: list[str], node_key: str) -> bool {
    for step in path {
        if step == node_key {
            return True;
        }
    }
    return False;
}

obj RunState {
    has _path: list[str];
    has _cursor: str;

    def path_keys() -> list[str] {
        return list(self._path);
    }

    def cursor_key() -> str {
        return self._cursor;
    }

    def has_visited(node_key: str) -> bool {
        return _linear_contains(self._path, node_key);
    }

    def move_to(node_key: str) -> RunState {
        return RunState(self._path + [node_key], node_key);
    }

    def copy() -> RunState {
        return RunState(list(self._path), self._cursor);
    }
}

obj FrontierEntry {
    has node_key: str;
    has state: RunState;
}

obj GuideDefinition {
    has edges: dict[str, list[str]];
    has nodes: dict[str, GuideNode] = {};

    def postinit {
        norm: dict[str, list[str]] = {};
        for (origin, targets) in self.edges.items() {
            norm[origin] = list(targets);
        }
        self.edges = norm;
        for origin in sorted(self.edges.keys()) {
            self._ensure(origin);
            for target in self.edges[origin] {
                self._ensure(target);
            }
        }
        for origin in sorted(self.edges.keys()) {
            o = self.nodes[origin];
            for target in self.edges[origin] {
                t = self.nodes[target];
                o +>:LeadsTo:+> t;
            }
        }
    }

    def _ensure(key: str) {
        if key not in self.nodes {
            nd = GuideNode(key=key);
            root ++> nd;
            self.nodes[key] = nd;
        }
    }

    def edges_from(origin: str) -> list[str] {
        stored = self.edges.get(origin, None);
        if stored is None {
            return [];
        }
        return list(stored);
    }

    def node_keys() -> list[str] {
        discovered: list[str] = [];
        seen: dict[str, bool] = {};
        for origin in sorted(self.edges.keys()) {
            if not (origin in seen) {
                seen[origin] = True;
                discovered.append(origin);
            }
            for target in self.edges[origin] {
                if not (target in seen) {
                    seen[target] = True;
                    discovered.append(target);
                }
            }
        }
        return discovered;
    }
}

walker RunToBfs {
    has edge_lists: dict[str, list[str]] = {};
    has acyclic: bool = True;
    has goal: str = "";
    has frontier: list[FrontierEntry] = [];
    has hit: RunState | None = None;

    can run with Root entry {
        nxt: list[FrontierEntry] = [];
        for item in self.frontier {
            if item.node_key == self.goal {
                self.hit = item.state;
                disengage;
            }
            for nxt_key in self.edge_lists.get(item.node_key, []) {
                if self.acyclic and item.state.has_visited(nxt_key) {
                    continue;
                }
                nxt.append(
                    FrontierEntry(
                        node_key=nxt_key,
                        state=item.state.move_to(nxt_key),
                    )
                );
            }
        }
        if self.hit is not None {
            disengage;
        }
        if len(nxt) == 0 {
            disengage;
        }
        inner = root spawn RunToBfs(
            edge_lists=self.edge_lists,
            acyclic=self.acyclic,
            goal=self.goal,
            frontier=nxt,
            hit=None,
        );
        if inner.hit is not None {
            self.hit = inner.hit;
        }
    }
}

walker ReachBfs {
    has edge_lists: dict[str, list[str]] = {};
    has acyclic: bool = True;
    has frontier: list[FrontierEntry] = [];
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};

    can run with Root entry {
        nxt: list[FrontierEntry] = [];
        for item in self.frontier {
            if not (item.node_key in self.claimed) {
                self.claimed[item.node_key] = True;
                self.order.append(item.node_key);
            }
            for nxt_key in self.edge_lists.get(item.node_key, []) {
                if self.acyclic and item.state.has_visited(nxt_key) {
                    continue;
                }
                if nxt_key in self.claimed {
                    continue;
                }
                nxt.append(
                    FrontierEntry(
                        node_key=nxt_key,
                        state=item.state.move_to(nxt_key),
                    )
                );
            }
        }
        if len(nxt) == 0 {
            skip;
        }
        root spawn ReachBfs(
            edge_lists=self.edge_lists,
            acyclic=self.acyclic,
            frontier=nxt,
            order=self.order,
            claimed=self.claimed,
        );
    }
}

obj GuideRunner {
    has guide: GuideDefinition;
    has acyclic: bool = True;

    def run_to(start: str, goal: str) -> RunState | None {
        w = root spawn RunToBfs(
            edge_lists=self.guide.edges,
            acyclic=self.acyclic,
            goal=goal,
            frontier=[
                FrontierEntry(
                    node_key=start,
                    state=RunState([start], start),
                )
            ],
            hit=None,
        );
        return w.hit;
    }

    def reachable_keys(start: str) -> list[str] {
        w = root spawn ReachBfs(
            edge_lists=self.guide.edges,
            acyclic=self.acyclic,
            frontier=[
                FrontierEntry(
                    node_key=start,
                    state=RunState([start], start),
                )
            ],
            order=[],
            claimed={},
        );
        return w.order;
    }

    def transition_guard_calls(start: str) -> int {
        calls = 0;
        state = RunState([start], start);
        for nxt in self.guide.edges_from(start) {
            calls += 1;
            if self.acyclic and state.has_visited(nxt) {
                continue;
            }
        }
        for nxt in self.guide.edges_from(start) {
            child = state.move_to(nxt);
            for leaf in self.guide.edges_from(nxt) {
                calls += 1;
                if self.acyclic and child.has_visited(leaf) {
                    continue;
                }
            }
        }
        return calls;
    }
}

test "diamond adversarial reachable revisit order" {
    guide = GuideDefinition({
        "hub": ["right", "left"],
        "left": ["leaf"],
        "right": ["leaf"],
    });
    runner = GuideRunner(guide, acyclic=True);
    assert runner.reachable_keys("hub") == ["hub", "right", "left", "leaf"];;
}

test "run to shortest path under adversarial diamond order" {
    guide = GuideDefinition({
        "hub": ["right", "left"],
        "left": ["goal"],
        "right": ["mid"],
        "mid": ["goal"],
    });
    runner = GuideRunner(guide, acyclic=True);
    hit = runner.run_to("hub", "goal");
    assert hit is not None;;
    assert hit.path_keys() == ["hub", "left", "goal"];;
    assert hit.cursor_key() == "goal";;
}

test "unknown id tolerance missing start and goal" {
    guide = GuideDefinition({
        "start": ["left", "right"],
        "left": [],
        "right": [],
    });
    runner = GuideRunner(guide, acyclic=True);
    assert guide.edges_from("phantom") == [];;
    assert runner.run_to("phantom", "start") is None;;
    assert runner.run_to("start", "phantom") is None;;
    assert runner.reachable_keys("phantom") == ["phantom"];;
    assert runner.reachable_keys("nowhere") == ["nowhere"];;
}

test "run state visited set survives long path and move_to" {
    state = RunState(["a", "b", "c", "d", "e"], "e");
    assert state.has_visited("a") is True;;
    assert state.has_visited("z") is False;;
    nxt = state.move_to("f");
    assert nxt.has_visited("a") is True;;
    assert nxt.has_visited("f") is True;;
    assert nxt.has_visited("z") is False;;
    assert nxt.path_keys() == ["a", "b", "c", "d", "e", "f"];;
}

test "transition guard calls lonely origin zero" {
    guide = GuideDefinition({
        "lonely": [],
        "busy": ["a", "b"],
        "a": ["c"],
        "b": ["c"],
        "c": [],
    });
    runner = GuideRunner(guide, acyclic=True);
    assert runner.transition_guard_calls("lonely") == 0;;
    assert runner.transition_guard_calls("busy") == 4;;
}

test "node keys discovers dangling targets only referenced" {
    guide = GuideDefinition({
        "a_first": ["b"],
        "z_last": ["orphan_only"],
    });
    assert guide.node_keys() == ["a_first", "b", "z_last", "orphan_only"];;
    assert guide.edges_from("orphan_only") == [];;
}
