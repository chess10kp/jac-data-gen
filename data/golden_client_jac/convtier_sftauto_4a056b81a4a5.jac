def insertion_sort(nums: Any) -> object {
    for i in range(1, len(nums)) {
        key = nums[i];
        j = i - 1;
        while ((j >= 0) and (nums[j] > key)) {
            nums[(j + 1)] = nums[j];
            j -= 1;
        }
        nums[(j + 1)] = key;
    }
    return nums;
}



with entry {
    print(insertion_sort([2, 7]));
    print(insertion_sort([2]));
    print(insertion_sort([34]));
}
