node Item { has value: int = 0; }

walker MyWalker {
    has param: int = 0;

    can visit with Root entry {
        visit [-->];
    }
    can collect with Item entry {
        report here.value;
        visit [-->];
    }
}

with entry {
    node1 = Item(value=1);
    node2 = Item(value=2);
    node3 = Item(value=3);
    root ++> node1 ++> node2 ++> node3;

    # Basic spawn
    result = root spawn MyWalker();

    # Spawn with parameters
    result = root spawn MyWalker(param=10);

    # Access results
    print(result.reports);  # All reported values
}
