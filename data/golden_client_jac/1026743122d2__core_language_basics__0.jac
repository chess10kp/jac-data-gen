def example() {
    # Generator expression (lazy)
    squares = (x ** 2 for x in range(1000000));

    # List comprehension (eager)
    squares_list = [x ** 2 for x in range(100)];
}
