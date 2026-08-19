def sum_even_numbers_iterative(lst: Any) -> object {
    total = 0;
    stack = [lst];
    while stack {
        current = stack.pop();
        if isinstance(current, `list) {
            stack.extend(current);
        } elif (isinstance(current, int) and ((current % 2) == 0)) {
            total += current;
        }
    }
    return total;
}



with entry {
    print(sum_even_numbers_iterative('hello'));
    print(sum_even_numbers_iterative(10));
    print(sum_even_numbers_iterative(2));
}
