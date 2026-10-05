node Task {
    has done: bool = False;
}

with entry {
    # comment
    everything = [root-->];
    print(len(everything));
    pending = [root-->[?:Task, done == False]];
}
