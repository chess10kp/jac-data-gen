def find_second_largest(lst: Any) -> object {
    largest = float('-inf');
    second_largest = float('-inf');
    for num in lst {
        if (num > largest) {
            second_largest = largest;
            largest = num;
        } elif ((num > second_largest) and (num != largest)) {
            second_largest = num;
        }
    }
    return second_largest;
}



with entry {
    print(find_second_largest([]));
}
