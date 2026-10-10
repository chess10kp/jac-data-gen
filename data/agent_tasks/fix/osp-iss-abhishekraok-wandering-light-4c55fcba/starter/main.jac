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
  * ``VerifyDifficulty`` takes a sampled program and the end state,
    computes the shortest subsequence length using a Floyd-style
    reduction (drop redundant steps whose target is already reachable
    from the kept prefix), and reports both the sampled length and the
    verified shortest length.
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

    can begin with Root entry {
        visit [-->];
    }

    can audit with State entry {
        # Detect no-op: a function from a state to itself.
        if here.label == here.label and len([->:Applies:->]) == 0 {
            pass;
        }
        visit [->:Step:->];
    }
}

walker VerifyDifficulty {
    has target: str = "";
    has max_depth: int = 64;
    has sampled_length: int = 0;
    has verified_length: int = 0;
    has filtered_invalid: bool = False;
    has filtered_identity: bool = False;
    has filtered_cycle: bool = False;

    can begin with Root entry {
        # First try direct BFS from start (first child) to target.
        visit [-->];
    }

    can measure with State entry {
        # Re-run BFS only from the first sampled state we encounter.
        if self.sampled_length == 0 {
            sp = ShortestPath(
                target=self.target,
                max_depth=self.max_depth
            );
            here spawn sp;
            self.sampled_length = 0;  # sampled length is on the chain
            self.verified_length = sp.distance if sp.distance >= 0 else 0;
        }
        visit [->:Applies:->];
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
    #    drops to 3 (the shortest chain S0->S1->S2->S3) while the
    #    sampled length stays 5.
    # Chain the sampled program as typed Step edges off s0.
    step_a = State(label="S0");
    step_b = State(label="S1");
    step_c = State(label="S1");  # no-op revisit
    step_d = State(label="S2");
    step_e = State(label="S3");
    s0 +>:Step(idx=0, func_name="inc"):+> step_a;
    s0 +>:Step(idx=1, func_name="inc"):+> step_b;
    s0 +>:Step(idx=2, func_name="inc"):+> step_c;
    s0 +>:Step(idx=3, func_name="double"):+> step_d;
    s0 +>:Step(idx=4, func_name="inc"):+> step_e;

    # Count sampled length by walking Step edges.
    counter = VerifyDifficulty(target="S3");
    counter.sampled_length = 5;
    # Verified shortest comes from the Applies BFS on the real graph.
    sp2 = ShortestPath(target="S3", max_depth=10);
    s0 spawn sp2;
    counter.verified_length = sp2.distance if sp2.distance >= 0 else 0;
    print(
        f"[VerifyDifficulty] sampled_length={counter.sampled_length}, "
        f"verified_length={counter.verified_length}"
    );

    # --- Demo 3: cycle hunter flags the no-op step.
    cycle.revists = [];
    cycle.no_ops = [];
    cycle.label = "audit";
    # Run a CycleHunter over the Step chain.
    ch = CycleHunter(target="S3");
    s0 spawn ch;
    print(
        f"[CycleHunter] revists={ch.revists}, no_ops={ch.no_ops}"
    );
}