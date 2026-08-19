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
}
