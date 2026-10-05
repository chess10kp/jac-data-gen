node Task {
    has done: bool = False;
}

with entry {
    everything = [root-->];
    tasks = [root-->[?:Task]];
    pending = [root-->[?:Task, done == False]];
    print(len(everything), len(tasks), len(pending));
}
