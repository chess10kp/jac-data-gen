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

    # Nested list comprehension (a 3x3 multiplication grid)
    matrix = [[i * j for j in range(3)] for i in range(3)];

    # Dict comprehension over zipped pairs
    lengths = {s: len(s) for s in strings};
}
