def find_second_largest(lst: Any) -> object {
    largest = float('-inf');
    second_largest = float('-inf');
    for num in lst {
        if (num > largest) {
            second_largest = largest;
            largest = num;
        } elif (num > second_largest) {
            second_largest = num;
        }
    }
    return second_largest;
}



with entry {
    print(find_second_largest([1, 2, 4]));
    print(find_second_largest([1, 2]));
    print(find_second_largest([5, 5, 5]));
}
