# A node is like an object that can live in a graph
node Task {
    has title: str;
    has done: bool = False;
}

with entry {
    # Connect nodes to the built-in root node
    root ++> Task(title="Buy groceries");
    root ++> Task(title="Write code");

    # Query connected nodes
    tasks = [root-->][?:Task];
    for t in tasks {
        print(t.title);
    }
}
