def find_triplet(nums: Any) -> object {
    n = len(nums);
    for i in range((n - 2)) {
        for j in range((i + 1), (n - 1)) {
            for k in range((j + 1), n) {
                if ((nums[i] < 0) and (nums[j] > 0) and (nums[k] == 0)) {
                    if ((nums[i] + nums[j] + nums[k]) == 0) {
                        return [nums[i], nums[j], nums[k]];
                    }
                }
            }
        }
    }
    return [];
}



with entry {
    print(find_triplet([]));
}
