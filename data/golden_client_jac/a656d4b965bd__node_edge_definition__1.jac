node DataNode {
    has value: int = 0;
}

walker DataCollector {
    can start with Root entry {
        visit [-->];
    }

    can collect with DataNode entry {
        report here.value;  # Continues execution
        visit [-->];
    }
}

with entry {
    root ++> DataNode(value=1);
    result = root spawn DataCollector();
    all_values = result.reports;  # List of reported values
}
