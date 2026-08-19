def find_duplicates(nums: Any) -> object {
    duplicates = [];
    n = len(nums);
    for i in range(n) {
        if (nums[i] is None) {
            continue;
        }
        for j in range((i + 1), n) {
            if (nums[i] == nums[j]) {
                duplicates.append(nums[i]);
                nums[j] = None;
            }
        }
    }
    return duplicates;
}



with entry {
    print(find_duplicates([81]));
}
