node DataNode {
    has value: int;
}

walker Counter {
    has count: int = 0;

    can count_nodes with DataNode entry {
        self.count += 1;
        visit [-->];
    }
}

with entry {
    root ++> DataNode(value=1) ++> DataNode(value=2);
    walker_instance = Counter();
    root spawn walker_instance;
    print(f"Counted {walker_instance.count} nodes");
}
