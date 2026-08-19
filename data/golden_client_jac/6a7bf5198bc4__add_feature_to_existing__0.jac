obj Item {
    has value: int = 0;
    has active: bool = True;
}

def example() -> list {
    items = [Item(value=1), Item(value=-1), Item(value=2)];
    valid_items = items[?value > 0];

    # New: compound filter - positive AND active
    positive_active = items[?value > 0, active == True];
    return positive_active;
}

with entry {
    result = example();
    print(len(result));
}
