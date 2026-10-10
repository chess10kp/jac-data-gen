"""Task Spaces: a config-driven DAG of workflow steps with gated handoffs.

Models the essential scenario from banso-labs/banso issue #571: a canonical
workflow DAG, task-scoped routes over it, a ready-set scheduler, gate
evaluation before handoff, fan-out / fan-in, and restart-safe persistence.
The hand-rolled parent-id / adjacency plumbing collapses into typed edges
and a walker that performs the ready-set traversal.
"""

node Step {
    has title: str = "";
    has kind: str = "execute";          # execute | critique | test | review | audit | verify
    has attempts: int = 0;
    has done: bool = False;
    has space_id: str = "";             # marks the step as task-scoped
    has join_policy: str = "all";       # all | any
    has concurrency: int = 1;
}

edge Next { }                           # canonical DAG successor (typed edge carries meaning)
edge Branch { }                         # fan-out branch edge (typed edge carries meaning)

node Gate {
    has name: str = "";
    has verdict: str = "pass";          # pass | fail | reask | park | warn
    has registered: bool = True;
    has raises: bool = False;           # when True, evaluator throws to simulate an error
}

edge GuardedBy { }                      # step --GuardedBy--> gate (typed edge carries meaning)

node SpaceState {
    has route: str = "default";
    has active: list[str] = [];
    has completed: list[str] = [];
    has stable_ids: list[str] = [];
    has log: list[str] = [];
    has seen: list[str] = [];           # restart-replay guard set
}

walker Scheduler {
    has state: SpaceState = SpaceState();

    can start with Root entry {
        # Resolve route: explicit > detection > default (every decision logged).
        explicit = "full-review" if "#route:full-review" in self.state.route else "";
        detection = "";                 # no detection rules configured in this demo
        chosen = explicit if explicit else (detection if detection else "default");
        self.state.route = chosen;
        self.state.log.append(f"route-resolved: explicit={explicit!r} detection={detection!r} chosen={chosen!r}");
        visit [-->];
    }

    can schedule with Step entry {
        # Cycle policy: ready-set guard so cyclic DAGs cannot loop forever.
        if here.title in self.state.seen {
            self.state.log.append(f"cycle-guard-skip: {here.title}");
            disengage;
        }
        self.state.seen.append(here.title);

        # Evaluate every exit gate before recording a handoff.
        all_clear = True;
        for gate in [->:GuardedBy:->] {
            if not gate.registered {
                self.state.log.append(f"gate-missing: step={here.title} gate={gate.name}");
                all_clear = False;
                break;
            }
            if gate.raises {
                self.state.log.append(f"gate-error: step={here.title} gate={gate.name}");
                all_clear = False;
                break;
            }
            if gate.verdict != "pass" {
                self.state.log.append(f"gate-fail: step={here.title} gate={gate.name} verdict={gate.verdict}");
                all_clear = False;
                break;
            }
        }

        if all_clear {
            here.done = True;
            here.attempts = here.attempts + 1;
            if here.title not in self.state.completed {
                self.state.completed.append(here.title);
            }
            if here.title in self.state.active {
                self.state.active.remove(here.title);
            }
            stable = f"wi-{here.space_id}-{here.title}-{here.attempts}";
            if stable not in self.state.stable_ids {
                self.state.stable_ids.append(stable);
            }
            self.state.log.append(f"step-done: {here.title} attempts={here.attempts} stable={stable}");
        } else {
            # Gate failure never silently advances: reask bounded then park.
            here.attempts = here.attempts + 1;
            if here.attempts >= 3 {
                self.state.log.append(f"step-parked: {here.title} after {here.attempts} attempts");
                disengage;
            } else {
                self.state.log.append(f"step-reask: {here.title} attempt={here.attempts}");
            }
        }

        # Ready-set: only fan-out when no unfinished required predecessor remains.
        if all_clear {
            for nxt in [->:Next:->] {
                unfinished = False;
                for pred in [<-:Next:<-] {
                    if not pred.done {
                        unfinished = True;
                        break;
                    }
                }
                # Join policy: "any" fires after one predecessor; "all" waits for every one.
                join_ok = False;
                preds = [<-:Next:<-];
                if here.join_policy == "any" and len(preds) > 0 {
                    join_ok = True;
                } else {
                    join_ok = not unfinished;
                }
                if join_ok {
                    if nxt.title not in self.state.active {
                        self.state.active.append(nxt.title);
                    }
                    self.state.log.append(f"handoff: {here.title} -> {nxt.title}");
                }
            }
        }

        visit [-->];
    }
}

with entry {
    # Canonical DAG for the #route:full-review route:
    #   execute -> {critique, test} (fan-out) -> review (fan-in, all-predecessor)
    execute = Step(title="execute", space_id="sp-exec", concurrency=1);
    critique = Step(title="critique", space_id="sp-crit", concurrency=1);
    test = Step(title="test", space_id="sp-test", concurrency=1);
    review = Step(title="review", space_id="sp-rev", join_policy="all", concurrency=1);

    # Typed edges for canonical DAG successors.
    execute +>:Next:+> critique;
    execute +>:Next:+> test;
    critique +>:Next:+> review;
    test +>:Next:+> review;

    # Custom script/plugin space inserted via canonical config (no core handler).
    audit = Step(title="audit", kind="plugin", space_id="sp-audit");
    execute +>:Next:+> audit;
    audit +>:Next:+> review;

    # Gates on the execute step: every gate must pass before handoff.
    gate_ok = Gate(name="signed-off");
    gate_bad = Gate(name="missing-evaluator", registered=False);
    gate_err = Gate(name="evaluator-throws", raises=True);
    execute +>:GuardedBy:+> gate_ok;
    execute +>:GuardedBy:+> gate_bad;
    execute +>:GuardedBy:+> gate_err;

    root ++> execute;
    st = SpaceState(route="#route:full-review");
    root spawn Scheduler(state=st);

    # Show what the scheduler produced.
    print(f"route: {st.route}");
    print(f"completed: {st.completed}");
    print(f"active: {st.active}");
    print(f"stable_ids: {st.stable_ids}");
    for line in st.log {
        print(f"  log: {line}");
    }
}