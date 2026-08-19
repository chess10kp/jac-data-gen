def example() -> list {
    # Lazy: nothing is computed until we pull from it
    squares = (x ** 2 for x in range(1000000));

    # Eager: all 100 squares are built immediately
    squares_list = [x ** 2 for x in range(100)];

    # Pull only the first 5 from the lazy generator
    preview = [];
    for s in squares {
        preview.append(s);
        if len(preview) >= 5 {
            break;
        }
    }
    return preview + squares_list;
}

with entry {
    result = example();
    print(result[:5]);  # [0, 1, 4, 9, 16]
}
