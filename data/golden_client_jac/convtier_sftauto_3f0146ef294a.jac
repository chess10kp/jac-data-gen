def remove_duplicates(nums: Any) -> object {
    for i in range(len(nums)) {
        j = i + 1;
        while (j < len(nums)) {
            if (nums[j] == nums[i]) {
                nums.pop(j);
            } else {
                j += 1;
            }
        }
    }
    return nums;
}



with entry {
    print(remove_duplicates([]));
    print(remove_duplicates([216, -1728]));
    print(remove_duplicates([147, -21, -216, -1728]));
}
