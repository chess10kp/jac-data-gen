def find_seventh_smallest(nums: Any) -> object {
    smallest = float('inf');
    count = 0;
    for num in nums {
        if (num < smallest) {
            smallest = num;
        }
        count += 1;
        if (count == 7) {
            break;
        }
    }
    return smallest;
}



with entry {
    print(find_seventh_smallest([81]));
    print(find_seventh_smallest([]));
    print(find_seventh_smallest([100]));
}
