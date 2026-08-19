def find_reverse_difference(n: Any) -> object {
    reversed_num = int(str(n)[::-1]);
    difference = `abs((n - reversed_num));
    return difference;
}



with entry {
    print(find_reverse_difference(5));
    print(find_reverse_difference(10));
    print(find_reverse_difference(100));
}
