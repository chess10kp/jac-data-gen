node Task {
    has title: str;
    has done: bool = False;
}

walker ListTasks {
    can run with Root entry {
        tasks = [here-->][?:Task];
        for t in tasks {
            print(t.title);
        }
    }
}

with entry {
    root ++> Task(title="Buy groceries");
    root ++> Task(title="Write code");
    root spawn ListTasks();
}
