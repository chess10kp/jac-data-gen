def find_second_largest(numbers: Any) -> object {
    largest = second_largest=float('-inf');
    for num in numbers {
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
    print(find_second_largest([]));
    print(find_second_largest([-12, 6]));
    print(find_second_largest([-12, -6, -3, 21]));
}
