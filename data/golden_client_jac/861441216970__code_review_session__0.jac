node DataNode { has value: int = 0; }

walker DataCollector {
    has collected: list[int] = [];

    can start with Root entry { visit [-->]; }
    can collect with DataNode entry {
        self.collected.append(here.value);
        report here.value;
        visit [-->];
    }
}
