node DataNode {
    has value: int = 0;
}

walker DataCollector {
    can collect with DataNode entry {
        report here.value;
    }
}

with entry {
    root ++> DataNode(value=1);
    result = root spawn DataCollector();
    all_values = result.reports;
}
