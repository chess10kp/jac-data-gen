node DataNode { has value: int = 0; }

walker Collector {
    has items: list[int] = [];
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

with entry {
    root ++> DataNode(value=1) ++> DataNode(value=2);
    result = root spawn Collector();
    print(result.items);
}
