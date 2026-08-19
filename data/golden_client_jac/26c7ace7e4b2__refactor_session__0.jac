node Task {
    has title: str;
    has status: str = "pending";
    has priority: int = 1;
}
edge DependsOn {}
walker CheckReady {
    has ready_tasks: list = [];
    can start with Root entry;
    can check with Task entry;
}
walker MarkComplete {
    has task_title: str;
    can start with Root entry;
    can mark with Task entry {
        if here.title == self.task_title {
            here.status = "complete";
            print(f"Completed: {here.title}");
            disengage;
        }
        visit [-->];
    }
}
impl CheckReady.start {
    visit [-->];
}
impl CheckReady.check {
    if here.status != "pending" {
        return;
    }
    dependencies = [here ->:DependsOn:->];
    all_done = True;
    for dep in dependencies {
        if dep.status != "complete" {
            all_done = False;
            break;
        }
    }
    if all_done {
        self.ready_tasks.append(here.title);
    }
}
impl MarkComplete.start {
    visit [-->];
}
with entry {
    task1 = Task(title="Design database schema", priority=3);
    task2 = Task(title="Implement API", priority=3);
    task3 = Task(title="Create frontend", priority=2);
    task4 = Task(title="Write tests", priority=2);
    task5 = Task(title="Deploy to production", priority=3);
    task2 +>:DependsOn:+> task1;
    task3 +>:DependsOn:+> task2;
    task4 +>:DependsOn:+> task2;
    task5 +>:DependsOn:+> task3;
    task5 +>:DependsOn:+> task4;
    root ++> task1;
    root ++> task2;
    root ++> task3;
    root ++> task4;
    root ++> task5;
    checker = CheckReady();
    root spawn checker;
    print(f"Ready to work on: {checker.ready_tasks}");
    root spawn MarkComplete(task_title="Design database schema");
    checker2 = CheckReady();
    root spawn checker2;
    print(f"Now ready: {checker2.ready_tasks}");
}
