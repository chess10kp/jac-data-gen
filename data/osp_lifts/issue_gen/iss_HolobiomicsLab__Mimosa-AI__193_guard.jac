"""HolobiomicsLab/Mimosa-AI#193 — dependency-aware task knowledge flow."""

node Task {
    has task_id: str;
    has prompt: str;
    has final_answer: str = "";
    has depends_on: list[str] = [];
}

edge Depends {}

walker DependencyWalker {
    has start_id: str;
    has transitive: bool = False;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Task entry {
        if here.task_id in self.claimed {
            skip;
        }
        self.claimed[here.task_id] = True;
        print("dependency " + here.task_id);

        if here.task_id != self.start_id {
            self.found.append(here.task_id);
        }

        if self.transitive {
            for dep in [here ->:Depends:->][?:Task] {
                visit :0: [dep];
            }
        } else {
            if here.task_id == self.start_id {
                for dep in [here ->:Depends:->][?:Task] {
                    visit :0: [dep];
                }
            }
        }
    }
}

def task_by_id(tasks: list[Task], task_id: str) -> Task | None {
    for task in tasks {
        if task.task_id == task_id {
            return task;
        }
    }
    return None;
}

def connect_dependency(task: Task, dependency: Task) -> None {
    task.depends_on.append(dependency.task_id);
    task +>:Depends:+> dependency;
}

def dependency_ids(target: Task, transitive: bool = False) -> list[str] {
    w = target spawn DependencyWalker(
        start_id=target.task_id,
        transitive=transitive,
        claimed={},
        found=[]
    );
    return w.found;
}

def token_count(text: str) -> int {
    if len(text) == 0 {
        return 0;
    }
    return len(text.split());
}

def measure_forwarded_tokens(
    target: Task,
    task_history: list[Task],
    knowledge_flow: str = "all",
    transitive: bool = False
) -> dict[str, int] {
    allowed: list[str] = [];
    if knowledge_flow == "dependencies" {
        allowed = dependency_ids(target, transitive);
    }

    result: dict[str, int] = {};
    for completed in task_history {
        if knowledge_flow == "all" or completed.task_id in allowed {
            result[completed.task_id] = token_count(completed.final_answer);
        }
    }
    return result;
}

def _build_knowledge_aware_task(
    target: Task,
    task_history: list[Task],
    knowledge_flow: str = "all",
    transitive: bool = False
) -> str {
    allowed: list[str] = [];
    if knowledge_flow == "dependencies" {
        allowed = dependency_ids(target, transitive);
    }

    task_text: str = target.prompt + "\n\nKnowledge:\n";
    for completed in task_history {
        if knowledge_flow == "all" or completed.task_id in allowed {
            task_text += "[" + completed.task_id + "] ";
            task_text += completed.final_answer + "\n";
        }
    }
    return task_text;
}

test "diamond revisit and cycle" {
    root_node = Task(task_id="root", prompt="assemble");
    left = Task(task_id="left", prompt="left", final_answer="left answer");
    right = Task(task_id="right", prompt="right", final_answer="right answer");
    shared = Task(task_id="shared", prompt="shared", final_answer="shared answer");

    connect_dependency(root_node, left);
    connect_dependency(root_node, right);
    connect_dependency(left, shared);
    connect_dependency(right, shared);
    connect_dependency(shared, root_node);

    ids = dependency_ids(root_node, True);
    assert (sorted(ids) == ["left", "right", "shared"]);
}

test "dependency filtering excludes unrelated history" {
    root_node = Task(task_id="root", prompt="assemble");
    left = Task(task_id="left", prompt="left", final_answer="left answer");
    shared = Task(task_id="shared", prompt="shared", final_answer="shared answer");
    unrelated = Task(task_id="unrelated", prompt="other", final_answer="unrelated answer");

    connect_dependency(root_node, left);
    connect_dependency(left, shared);

    history: list[Task] = [left, shared, unrelated];
    prompt = _build_knowledge_aware_task(root_node, history, "dependencies", True);

    assert ("left answer" in prompt);
    assert ("shared answer" in prompt);
    assert ("unrelated answer" not in prompt);
}

test "default all forwards every completed answer" {
    root_node = Task(task_id="root", prompt="assemble");
    declared = Task(task_id="declared", prompt="declared", final_answer="one");
    unrelated = Task(task_id="unrelated", prompt="other", final_answer="two words");

    connect_dependency(root_node, declared);
    history: list[Task] = [declared, unrelated];

    prompt = _build_knowledge_aware_task(root_node, history);
    counts = measure_forwarded_tokens(root_node, history);

    assert ("one" in prompt);
    assert ("two words" in prompt);
    assert (counts["declared"] == 1);
    assert (counts["unrelated"] == 2);
}

test "unknown task id is tolerated" {
    tasks: list[Task] = [];
    known = Task(task_id="known", prompt="known");
    tasks.append(known);

    missing = task_by_id(tasks, "absent");
    assert (missing == None);
}

test "empty history produces empty measurements" {
    solo = Task(task_id="solo", prompt="work");
    history: list[Task] = [];

    prompt = _build_knowledge_aware_task(solo, history, "dependencies");
    counts = measure_forwarded_tokens(solo, history, "dependencies");

    assert (prompt == "work\n\nKnowledge:\n");
    assert (len(counts) == 0);
}
