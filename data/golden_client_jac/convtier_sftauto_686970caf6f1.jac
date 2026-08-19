def find_smallest_number(numbers: Any) -> object {
    smallest = float('inf');
    for num in numbers {
        if (num < smallest) {
            smallest = num;
        }
    }
    return smallest;
}



with entry {
    print(find_smallest_number([81]));
    print(find_smallest_number([]));
    print(find_smallest_number([100]));
}
