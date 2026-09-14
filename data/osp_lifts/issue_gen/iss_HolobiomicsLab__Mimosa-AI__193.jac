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
