def find_smallest_positive_multiple(array: Any) -> object {
    for num in array {
        if ((num > 5) and ((num % 3) == 0) and ((num % 7) == 0) and is_prime(num)) {
            return num;
        }
    }
    return -1;
}



with entry {
    print(find_smallest_positive_multiple([]));
}
