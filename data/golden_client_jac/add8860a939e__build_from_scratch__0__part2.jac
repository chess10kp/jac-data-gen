node Task {
    has title: str,
        done: bool = False;
}

with entry {
    # Create tasks and connect them to root
    root ++> Task(title="Buy groceries");
    root ++> Task(title="Team standup at 10am");
    root ++> Task(title="Go for a run");

    print("Created 3 tasks!");
}
