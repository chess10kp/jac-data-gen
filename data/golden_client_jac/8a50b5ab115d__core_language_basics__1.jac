def example() {
    # List comprehension
    squares = [x ** 2 for x in range(10)];

    # With condition
    evens = [x for x in range(20) if x % 2 == 0];

    # Dict comprehension
    squared_dict = {x: x ** 2 for x in range(5)};

    # Set comprehension
    strings = ["hello", "world", "hi"];
    unique_lengths = {len(s) for s in strings};

    # Generator expression
    gen = (x ** 2 for x in range(1000000));
}
