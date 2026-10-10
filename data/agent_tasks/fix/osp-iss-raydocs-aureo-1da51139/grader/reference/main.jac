"""Board projection walker: model objectives, tasks, agents, and attempts.

The hand-rolled source maintains a Board with parent/child task IDs, agent
assignment lookups, and walkable dependency graphs for "next runnable" and
"reconnect" semantics. This demo lifts that machinery into native Jac:

  * Objective, Task, Agent, Attempt are node archetypes with typed fields.
  * Decomposes, DependsOn, AssignedTo, Produces are typed edges.
  * BoardInspector is a walker that traverses the graph, accumulates
    per-objective state, detects dependency cycles, and emits one final
    report (the single exit-point idiom).
  * Walker carries an explicit guard set so cycle-prone edges (DependsOn)
    cannot loop forever, mirroring the source's cycle safety.
"""

node Objective {
    has title: str = "";
    has goal: str = "";
}

node Task {
    has title: str = "";
    has state: str = "pending";
    has context: str = "";
    has evidence: str = "";
    has attempt_count: int = 0;
}

node Agent {
    has name: str = "";
    has role: str = "";
}

node Attempt {
    has note: str = "";
    has outcome: str = "unknown";
}

edge Decomposes: any --> any {}
edge DependsOn: any --> any {}
edge AssignedTo: any --> any {}
edge Produces: any --> any {}

walker BoardInspector {
    has objective_count: int = 0;
    has task_count: int = 0;
    has ready_count: int = 0;
    has cycle_found: bool = False;
    has visited_tasks: list[any] = [];

    can start with Root entry {
        visit [-->];
    }

    can audit_objective with Objective entry {
        self.objective_count += 1;
        print(f"[OBJECTIVE] {here.title}: {here.goal}");
        visit [->:Decomposes:->];
    }

    can audit_task with Task entry {
        if here in self.visited_tasks {
            return;
        }
        self.visited_tasks.append(here);
        self.task_count += 1;
        is_runnable = here.state == "ready" or here.state == "pending";
        blocked = False;
        for pred in [->:DependsOn:->] {
            if pred.state != "done" {
                blocked = True;
                break;
            }
        }
        if is_runnable and not blocked {
            self.ready_count += 1;
            print(f"  [RUNNABLE] {here.title} (state={here.state}, "
                  f"attempts={here.attempt_count})");
        } else {
            print(f"  [BLOCKED]  {here.title} (state={here.state})");
        }
        if here.context != "" {
            print(f"    context : {here.context}");
        }
        if here.evidence != "" {
            print(f"    evidence: {here.evidence}");
        }
        visit [->:Produces:->];
        visit [->:Decomposes:->];
    }

    can audit_attempt with Attempt entry {
        label = "OK " if here.outcome == "success" else "BAD";
        print(f"    [ATTEMPT {label}] {here.note}");
        visit [-->];
    }

    can detect_cycle with Task entry {
        for nxt in [->:DependsOn:->] {
            if nxt in self.visited_tasks {
                self.cycle_found = True;
                print(f"  [CYCLE] dependency loop detected via {here.title}");
                break;
            }
        }
        visit [->:DependsOn:->];
    }

    can finish with Root entry {
        print("");
        print(f"inspected {self.objective_count} objectives, "
              f"{self.task_count} tasks, "
              f"{self.ready_count} runnable, "
              f"cycle={self.cycle_found}");
    }
}

with entry {
    obja = Objective(title="Ship Board projection",
                     goal="Let humans and agents read the same board truth");
    t_setup = Task(title="Add board create/show CLI",
                   state="done",
                   context="ago board create --title=...",
                   evidence="commit a1");
    t_api = Task(title="Expose POST/GET board API",
                 state="done",
                 evidence="commit a2");
    t_ui = Task(title="Render objective + task projection",
                state="ready",
                context="bun web typecheck + build",
                attempt_count=1);
    t_reconnect = Task(title="Sequence reconnect state recovery",
                       state="pending",
                       context="must restore same board ID");
    agent = Agent(name="aurora", role="implementer");
    attempt_ok = Attempt(note="first attempt succeeded", outcome="success");
    attempt_fail = Attempt(note="web build failed", outcome="failure");

    root +>:Decomposes:+> obja;
    obja +>:Decomposes:+> t_setup;
    obja +>:Decomposes:+> t_api;
    obja +>:Decomposes:+> t_ui;
    obja +>:Decomposes:+> t_reconnect;

    t_ui +>:DependsOn:+> t_api;
    t_reconnect +>:DependsOn:+> t_ui;

    t_setup +>:AssignedTo:+> agent;
    t_ui +>:Produces:+> attempt_fail;
    t_setup +>:Produces:+> attempt_ok;

    root spawn BoardInspector();
}
