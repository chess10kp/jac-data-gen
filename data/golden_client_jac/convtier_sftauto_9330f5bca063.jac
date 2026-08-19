def find_second_smallest(nums: Any) -> object {
    smallest = float('inf');
    second_smallest = float('inf');
    for num in nums {
        if (num < smallest) {
            second_smallest = smallest;
            smallest = num;
        } elif (num < second_smallest) {
            second_smallest = num;
        }
    }
    return second_smallest;
}



with entry {
    print(find_second_smallest([81]));
    print(find_second_smallest([-8, -4, 2]));
    print(find_second_smallest([-2, -1, 4, 7]));
}
