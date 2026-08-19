def example() {
    # Basic by expression
    result = "hello" by "world";

    # Chained by expressions (right-associative)
    result = "a" by "b" by "c";  # Parsed as: "a" by ("b" by "c")

    # With expressions
    result = (1 + 2) by (3 * 4);
}
