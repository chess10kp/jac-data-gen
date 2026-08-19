with entry {
    # Traditional way
    squares = [];
    for i = 0 to i < 5 by i += 1 {
        squares.append(i ** 2);
    }
    print(squares);  # [0, 1, 4, 9, 16]

    # List comprehension way
    squares = [i ** 2 for i in range(5)];
    print(squares);  # [0, 1, 4, 9, 16]

    # With condition
    evens = [i for i in range(10) if i % 2 == 0];
    print(evens);  # [0, 2, 4, 6, 8]
}
