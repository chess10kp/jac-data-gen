def find_second_smallest(numbers: Any) -> object {
    smallest = float('inf');
    second_smallest = float('inf');
    for num in numbers {
        if (num < smallest) {
            second_smallest = smallest;
            smallest = num;
        } elif ((num < second_smallest) and (num != smallest)) {
            second_smallest = num;
        }
    }
    return second_smallest;
}



with entry {
    print(find_second_smallest([4, 2, 1]));
    print(find_second_smallest([5, 5, 5]));
    print(find_second_smallest([10, 20, 30]));
}
