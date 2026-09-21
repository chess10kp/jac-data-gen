"""Task scheduler that respects dependencies.

Build tasks point at the tasks that need them via Needs edges. A scheduler
walker gathers every task, then repeatedly schedules the tasks whose
prerequisites are all done -- Kahn's algorithm -- decrementing each
dependent's remaining-prerequisite counter as it goes.
"""

node Task {
    has name: str;
    has duration: int = 5;
    has indegree: int = 0;  # prerequisites not yet scheduled
    has seen: bool = False;
}

edge Needs: Task --> Task {}

walker Scheduler {
    has order: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can gather with Task entry {
        if here.seen {
            skip;
        }
        here.seen = True;
        visit [-->];
    }

    can plan with Root exit {
        # Deferred until the whole graph has been gathered.
        tasks = [-->][?:Task];

        for t in tasks {
            t.indegree = len([t <-:Needs:<-]);
        }

        done: list[str] = [];
        remaining = len(tasks);
        total_time = 0;
        while remaining > 0 {
            progressed = False;
            for t in tasks {
                if t.indegree != 0 or t.name in done {
                    continue;
                }
                self.order.append(t.name);
                done.append(t.name);
                total_time += t.duration;
                remaining -= 1;
                progressed = True;
                for dependent in [t ->:Needs:->] {
                    dependent.indegree -= 1;
                }
            }
            if not progressed {
                print("Dependency cycle among remaining tasks -- stuck.");
                break;
            }
        }

        print(f"Build order ({len(self.order)} of {len(tasks)} tasks, {total_time} min total):");
        for i in range(len(self.order)) {
            step = self.order[i];
            print(f"  {i + 1}. {step}");
        }
    }
}

with entry {
    # Reset anything a previous run left behind so the demo repeats
    # cleanly on the persistent root.
    for stale in [root -->][?:Task] {
        del stale;
    }

    setup = Task(name="setup", duration=5);
    compile_src = Task(name="compile", duration=20);
    gen_docs = Task(name="docs", duration=10);
    run_tests = Task(name="tests", duration=15);
    package = Task(name="package", duration=8);
    publish = Task(name="publish", duration=4);

    root ++> [
        setup,
        compile_src,
        gen_docs,
        run_tests,
        package,
        publish,
    ];

    # Edge direction: prerequisite --> dependent.
    setup +>: Needs() :+> compile_src;
    compile_src +>: Needs() :+> gen_docs;
    compile_src +>: Needs() :+> run_tests;
    compile_src +>: Needs() :+> package;
    gen_docs +>: Needs() :+> package;
    package +>: Needs() :+> publish;

    root spawn Scheduler();
}
