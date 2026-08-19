def example(skip_value: int, stop_value: int) {
    items = [1, 2, 3, 4, 5];
    for item in items {
        if item == skip_value {
            continue;
        }
        if item == stop_value {
            break;
        }
        print(item);
    }
}
