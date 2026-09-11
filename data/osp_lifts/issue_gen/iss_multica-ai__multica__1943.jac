// iss_multica-ai__multica__1943.jac

node Workflow {
    has start: str;
    has tasks: list[Task] = [];
    has result: list[str] = [];
}

node Task {
    has tid: str;
    has label: str;
}

edge Contains {}
edge Depends {}

walker RunWorkflow {
    has claimed: dict[str, bool] = {};
    has owner: Workflow | None = None;

    can begin with Workflow entry {
        self.owner = here;
        print("workflow started");
        for task in [here ->:Contains:->][?:Task] {
            if task.tid == here.start {
                visit [task];
            }
        }
    }

    can step with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if self.owner != None {
            self.owner.result.append(here.tid);
        }
        print(here.tid);
        for kid in [here ->:Depends:->][?:Task] {
            visit :0: [kid];
        }
    }
}

def workflow_order(
    task_ids: list[str],
    links: list[list[str]],
    start: str
) -> list[str] {
    flow: Workflow = Workflow(start=start);
    for tid in task_ids {
        task: Task = Task(tid=tid, label=tid);
        flow.tasks.append(task);
        flow +>:Contains:+> task;
    }

    for link in links {
        if len(link) == 2 {
            source: Task | None = None;
            target: Task | None = None;
            for task in flow.tasks {
                if task.tid == link[0] {
                    source = task;
                }
                if task.tid == link[1] {
                    target = task;
                }
            }
            if source != None and target != None {
                source +>:Depends:+> target;
            }
        }
    }

    found_start: bool = False;
    for task in flow.tasks {
        if task.tid == start {
            found_start = True;
        }
    }
    if not found_start {
        return flow.result;
    }

    with entry {
        root spawn RunWorkflow;
    }
    return flow.result;
}
