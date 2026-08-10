"""Splits a list into two pieces."""
def split[T](input_list: list[T]) -> tuple[list[T], list[T]] {
    midpoint = len(input_list) // 2;
    return (input_list[:midpoint], input_list[midpoint:]);
}