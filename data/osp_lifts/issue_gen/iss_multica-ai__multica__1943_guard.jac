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

test "diamond revisit is claimed once" {
    result: list[str] = workflow_order(
        ["A", "B", "C", "D"],
        [["A", "B"], ["A", "C"], ["B", "D"], ["C", "D"]],
        "A"
    );
    assert (len(result) == 4);
    assert ("A" in result);
    assert ("B" in result);
    assert ("C" in result);
    assert ("D" in result);
}

test "unknown start is tolerated" {
    result: list[str] = workflow_order(
        ["build", "review"],
        [["build", "review"]],
        "missing"
    );
    assert (len(result) == 0);
}

test "unknown edge endpoints are ignored" {
    result: list[str] = workflow_order(
        ["build", "review"],
        [["build", "missing"], ["missing", "review"]],
        "build"
    );
    assert (len(result) == 1);
    assert (result[0] == "build");
}

test "single task workflow runs" {
    result: list[str] = workflow_order(
        ["deploy"],
        [],
        "deploy"
    );
    assert (len(result) == 1);
    assert (result[0] == "deploy");
}
