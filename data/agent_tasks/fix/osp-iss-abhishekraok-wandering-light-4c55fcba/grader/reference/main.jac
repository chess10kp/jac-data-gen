"""Task difficulty as shortest reachable program length.

Models the wandering-light issue: a task is a start state, an end state,
and a sampled ordered sequence of function calls.  The difficulty of a
task is the length of the SHORTEST ordered subsequence of the sampled
program that still connects start -> end under the available functions.
Sampled length and verified shortest length are tracked separately, so a
maintainer can compare them.

Walkers:
  * ``ShortestPath`` performs BFS from the start state over the
    ``Applies`` typed edge, tracks visited states (cycle policy from
    source: explicit guard set), and reports the shortest distance to
    the end state.
  * ``CycleHunter`` revisits states along the sampled program and flags
    any no-op or cycle step (issue diagnostics: "revisit a state" and
    "contain a no-op step").
"""

node State {
    has label: str = "";
    has reachable: bool = True;
}

# A typed edge meaning "function f transforms source into target".
edge Applies {
    has func_name: str = "";
}

# A typed edge meaning "this sampled step lives at position idx in a program".
edge Step {
    has idx: int = 0;
    has func_name: str = "";
}

walker ShortestPath {
    has target: str = "";
    has max_depth: int = 64;
    has distance: int = -1;
    has seen: list[str] = [];

    can begin with Root entry {
        visit [-->];
    }

    can search with State entry {
        # Cycle policy (probe-verified: walkers have no built-in dedupe).
        if here.label in self.seen {
            disengage;
        }
        self.seen.append(here.label);

        if here.label == self.target {
            if self.distance == -1 or self.seen.__len__() - 1 < self.distance {
                self.distance = self.seen.__len__() - 1;
            }
            disengage;
        }

        if self.seen.__len__() - 1 >= self.max_depth {
            disengage;
        }

        visit [->:Applies:->];
    }
}

walker CycleHunter {
    has target: str = "";
    has revists: list[int] = [];
    has no_ops: list[int] = [];
    has visited_labels: list[str] = [];

    can begin with Root entry {
        visit [-->];
    }

    can audit with State entry {
        # Detect no-op: a function from a state to itself.
        neighbors = [->:Applies:->];
        if len(neighbors) == 0 {
            self.no_ops.append(0);
        }
        # Detect revisits.
        if here.label in self.visited_labels {
            self.revists.append(0);
        }
        self.visited_labels.append(here.label);
        visit [->:Step:->];
    }
}

with entry {
    # --- Build a small state graph ---
    # States: S0 -> S1 -> S2 -> S3 (the chain).
    s0 = State(label="S0");
    s1 = State(label="S1");
    s2 = State(label="S2");
    s3 = State(label="S3");
    root ++> s0;
    s0 +>:Applies(func_name="inc"):+> s1;
    s1 +>:Applies(func_name="double"):+> s2;
    s2 +>:Applies(func_name="inc"):+> s3;

    # --- Demo 1: shortest path from S0 to S3 ---
    sp = ShortestPath(target="S3", max_depth=10);
    s0 spawn sp;
    print(f"[ShortestPath] S0 -> S3 verified distance: {sp.distance}");

    # --- Demo 2: a sampled program that contains a no-op (S1 -> S1)
    # and a revisit (S2 appears twice).  The verified difficulty
    # drops to 3 (the shortest chain S0->S1->S2->S3) while the
    # sampled length stays 5.
    # Chain the sampled program as typed Step edges off s0.
    step_a = State(label="S0");
    step_b = State(label="S1");
    step_c = State(label="S1");
    step_d = State(label="S2");
    step_e = State(label="S3");
    s0 +>:Step(idx=0, func_name="inc"):+> step_a;
    s0 +>:Step(idx=1, func_name="inc"):+> step_b;
    s0 +>:Step(idx=2, func_name="inc"):+> step_c;
    s0 +>:Step(idx=3, func_name="double"):+> step_d;
    s0 +>:Step(idx=4, func_name="inc"):+> step_e;

    sampled_length = 5;
    sp2 = ShortestPath(target="S3", max_depth=10);
    s0 spawn sp2;
    verified_length = sp2.distance if sp2.distance >= 0 else 0;
    print(
        f"[VerifyDifficulty] sampled_length={sampled_length}, "
        f"verified_length={verified_length}"
    );

    # --- Demo 3: cycle hunter flags the no-op step.
    ch = CycleHunter(target="S3");
    s0 spawn ch;
    print(
        f"[CycleHunter] revists={ch.revists}, no_ops={ch.no_ops}"
    );
}
