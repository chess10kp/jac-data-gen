walker Collector {
    has items: list = [];
    has max_items: int = 10;

    can start with Root entry {
        print("Starting collection");
        visit [-->];
    }

    can collect with DataNode entry {
        if len(self.items) < self.max_items {
            self.items.append(here.value);
        }
        visit [-->];
    }
}
