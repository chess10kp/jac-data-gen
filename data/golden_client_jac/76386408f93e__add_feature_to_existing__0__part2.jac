node Task {
    has title: str,
        done: bool = False;
}

with entry {
    root ++> Task(title="Buy groceries");
    root ++> Task(title="Team standup at 10am");

    # Get ALL nodes connected from root
    everything = [root-->];

    # Filter by node type -- same [?:Type] syntax
    tasks = [root-->][?:Task];
    for task in tasks {
        status = "done" if task.done else "pending";
        print(f"[{status}] {task.title}");
    }

    # Filter by field value
    grocery_tasks = [root-->][?:Task, title == "Buy groceries"];

    # New: only the pending tasks, plus a count
    pending = [root-->][?:Task, done == False];
    for task in pending {
        print(f"TODO: {task.title}");
    }
    print(f"{len(pending)} task(s) still pending");
}
