def find_median(nums: Any) -> object {
    if not nums {
        raise ValueError("List is empty");
    }
    if not all(isinstance(num, int) for num in nums) {
        raise ValueError("List contains non-integer elements");
    }
    sorted_nums = sorted(nums);
    if ((len(sorted_nums) % 2) == 0) {
        return (
            (
                sorted_nums[(len(sorted_nums) // 2)] + sorted_nums[
                    ((len(sorted_nums) // 2) - 1)
                ]
            ) / 2
        );
    } else {
        return sorted_nums[(len(sorted_nums) // 2)];
    }
}



with entry {
    print(find_median([81]));
    print(find_median([100]));
    print(find_median([-8, -4, 2]));
}
