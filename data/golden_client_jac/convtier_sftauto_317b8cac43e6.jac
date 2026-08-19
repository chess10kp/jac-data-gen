def second_largest_index(nums: Any) -> object {
    largest = second_largest=0;
    for i in range(1, len(nums)) {
        if (nums[i] > nums[largest]) {
            second_largest = largest;
            largest = i;
        } elif ((nums[i] > nums[second_largest]) and (nums[i] != nums[largest])) {
            second_largest = i;
        }
    }
    return second_largest;
}



with entry {
    print(second_largest_index('hello'));
    print(second_largest_index('Racecar'));
    print(second_largest_index('abcabc'));
}
