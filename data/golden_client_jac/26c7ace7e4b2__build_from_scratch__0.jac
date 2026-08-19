node Task {
    has title: str;
    has status: str = "pending";
    has priority: int = 1;
}

edge DependsOn {}

walker CheckReady {
    has ready_tasks: list = [];
    can check with Task entry {
        if here.status != "pending" { return; }
        dependencies = [here ->:DependsOn:->];
        all_done = True;
        for dep in dependencies {
            if dep.status != "complete" { all_done = False; break; }
        }
        if all_done { self.ready_tasks.append(here.title); }
    }
}
