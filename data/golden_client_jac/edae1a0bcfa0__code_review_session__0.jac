node Item {
    has value: int;
}

walker ListItems {
    has items: list = [];

    can collect with `root entry {
        visit [-->];
    }

    can gather with Item entry {
        self.items.append(here.value);
        visit [-->];
    }

    can report_all with `root exit {
        report self.items;
    }
}
