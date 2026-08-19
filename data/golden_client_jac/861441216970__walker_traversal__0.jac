walker DataCollector {
    has reports: list[int];

    can start with Root entry { visit [-->]; }
    can collect with DataNode entry {
        report here.value;  # checked against int
        visit [-->];
    }
}
