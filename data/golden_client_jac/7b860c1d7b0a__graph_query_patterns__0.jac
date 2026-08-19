with entry {
    # Get all nodes connected from root as a list
    everything = [root-->];

    # Filter by node type
    tasks = [root-->][?:Task];

    # Filter by field value
    pending = [root-->][?:Task, done == False];
}
