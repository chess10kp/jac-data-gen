def count_quadruples(nums: Any) -> object {
    count = 0;
    for i in range(len(nums)) {
        for j in range((i + 1), len(nums)) {
            for k in range((j + 1), len(nums)) {
                for l in range((k + 1), len(nums)) {
                    if (nums[i] != nums[j] != nums[k] != nums[l]) {
                        if ((nums[i] + nums[j] + nums[k] + nums[l]) == 0) {
                            count += 1;
                        }
                    }
                }
            }
        }
    }
    return count;
}



with entry {
    print(count_quadruples('hello'));
}
