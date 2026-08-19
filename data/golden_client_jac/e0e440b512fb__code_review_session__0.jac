def example() {
    items = [1, 2, 3];
    for item in items {
        print(item);
    }
    for (idx, val) in enumerate(items) {
        print(f"{idx}: {val}");
    }
    for counter = 0 to counter < 10 by counter += 1 {
        print(counter);
    }
    for element in items {
        if element == 5 {
            break;
        }
    } else {
        print("Not found");
    }
}
