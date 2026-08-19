obj Item {
    has value: int = 0;
}

def example() {
    items = [Item(value=1), Item(value=-1), Item(value=2)];
    # The ? in filter comprehensions
    valid_items = items[?value > 0];  # Filter where value > 0
}
