def find_square_root(n: Any) -> object {
    if (n < 0) {
        raise ValueError("Input must be a non-negative number");
    } elif (n == 0) {
        return 0;
    }
    return find_square_root_recursive(n, 0, n);
}



with entry {
    print(find_square_root(0));
}
