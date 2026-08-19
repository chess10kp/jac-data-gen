def find_unique_sums(nums: Any) -> object {
    nums.sort();
    sums = `set();
    for i in range(len(nums)) {
        for j in range((i + 1), len(nums)) {
            sums.add((nums[i] + nums[j]));
        }
    }
    return sorted(`list(sums));
}



with entry {
    print(find_unique_sums([]));
}
