def example() -> list {
    items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

    if (n := len(items)) > 10 {
        print(f"List has {n} items, too many!");
    }

    data = [1, 2, 3];
    results = [y for x in data if (y := x * 2) > 2];

    text = "hello";
    print(f"Length: {(m := len(text))}, doubled: {m * 2}");

    # New: use walrus to capture and reuse a computed sum
    if (s := sum(items)) > 50 {
        print(f"Sum {s} exceeds 50");
    }
    return results;
}

with entry {
    print(example());
}
