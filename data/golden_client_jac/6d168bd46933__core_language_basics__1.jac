def example() {
    items = [1, 2, 3, 4, 5];

    for item in items {
        if item == 2 {
            continue;    # Skip to next iteration
        }
        if item == 4 {
            break;       # Exit loop
        }
        print(item);
    }
}
