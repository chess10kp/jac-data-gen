node DataNode {
    has value: int;
}
walker Counter {
    has count: int = 0;
    can start with Root entry;
    can count_nodes with DataNode entry;
}
impl Counter.start {
    self.count += 1;
    visit [-->];
}
impl Counter.count_nodes {
    self.count += 1;
    visit [-->];
}
with entry {
    root ++> DataNode(value=1) ++> DataNode(value=2);
    walker_instance = Counter();
    root spawn walker_instance;
    print(f"Counted {walker_instance.count} nodes");
}
