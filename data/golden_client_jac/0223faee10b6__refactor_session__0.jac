node Item { has value: int = 0; }

walker MyWalker {
    has param: int = 0;

    can visit_root with Root entry;
    can collect with Item entry;
}

impl MyWalker.visit_root {
    visit [-->];
}

impl MyWalker.collect {
    report here.value;
    visit [-->];
}

with entry {
    node1 = Item(value=1);
    node2 = Item(value=2);
    node3 = Item(value=3);
    root ++> node1 ++> node2 ++> node3;

    result = root spawn MyWalker();
    result = root spawn MyWalker(param=10);
    print(result.reports);
}
