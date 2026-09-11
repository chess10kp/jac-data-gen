"""lantisprime/episodic-memory#147 — OSP cycle detection on Trigger edges."""

node Event {
    has id: str;
}

edge Trigger {}

obj TriggerGraph {
    def add_trigger(source: str, target: str) -> None {
        src = self._ensure(source);
        tgt = self._ensure(target);
        src +>:Trigger:+> tgt;
    }

    def _ensure(event_id: str) -> Event {
        for e in [root -->][?:Event] {
            if e.id == event_id {
                return e;
            }
        }
        fresh = Event(id=event_id);
        root ++> fresh;
        return fresh;
    }

    def find_cycles() -> list[list[str]] {
        walker CycleFinder {
            has cycles: list[list[str]] = [];
            has path: list[str] = [];
            has claims: dict[str, bool] = {};
            has on_path: dict[str, bool] = {};

            can start with Root entry {
                visit [-->][?:Event];
            }

            can walk with Event entry {
                key = str(here.jid);
                if self.on_path.get(here.id, False) {
                    # cycle closed — record normalized cycle body
                    idx = 0;
                    for (i, pid) in enumerate(self.path) {
                        if pid == here.id {
                            idx = i;
                            break;
                        }
                    }
                    body = self.path[idx:];
                    if body not in self.cycles {
                        self.cycles.append(body);
                    }
                    skip;
                }
                if self.claims.get(key, False) {
                    skip;
                }
                self.claims[key] = True;
                self.path.append(here.id);
                self.on_path[here.id] = True;
                visit [-->][?:Event];
            }

            can unwind with Event exit {
                if len(self.path) > 0 and self.path[-1] == here.id {
                    self.path.pop();
                }
                self.on_path[here.id] = False;
            }

            can finish with Root exit {
                report sorted(self.cycles, key=lambda c: (len(c), c));
            }
        }
        result = root spawn CycleFinder();
        return result.reports[0] if result.reports else [];
    }

    def would_create_cycle(source: str, target: str) -> bool {
        if source == target {
            return True;
        }
        walker Reach {
            has goal: str;
            has found: bool = False;
            has claims: dict[str, bool] = {};

            can from_root with Root entry {
                for e in [-->][?:Event] {
                    if e.id == self.goal {
                        visit [e];
                    }
                }
            }

            can step with Event entry {
                if here.id == self.goal {
                    self.found = True;
                    disengage;
                }
                key = str(here.jid);
                if self.claims.get(key, False) {
                    skip;
                }
                self.claims[key] = True;
                visit [-->][?:Event] else {
                    disengage;
                }
            }
        }
        origin = None;
        for e in [root -->][?:Event] {
            if e.id == target {
                origin = e;
                break;
            }
        }
        if origin is None {
            return False;
        }
        w = origin spawn Reach(goal=source);
        return w.found;
    }

    def reachable_from(start: str) -> list[str] {
        walker CollectReach {
            has start_id: str;
            has claims: dict[str, bool] = {};
            has found: list[str] = [];

            can launch with Event entry {
                if here.id != self.start_id {
                    skip;
                }
                visit [-->][?:Event];
            }

            can gather with Event entry {
                key = str(here.jid);
                if self.claims.get(key, False) {
                    skip;
                }
                self.claims[key] = True;
                if here.id != self.start_id {
                    self.found.append(here.id);
                }
                visit [-->][?:Event] else {
                    disengage;
                }
            }
        }
        start_node = None;
        for e in [root -->][?:Event] {
            if e.id == start {
                start_node = e;
                break;
            }
        }
        if start_node is None {
            return [];
        }
        w = start_node spawn CollectReach(start_id=start);
        return sorted(w.found);
    }
}
