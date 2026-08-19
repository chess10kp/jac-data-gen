def find_fourth_largest(nums: Any) -> object {
    if (len(nums) < 4) {
        return None;
    }
    fourth_largest = float('-inf');
    for num in nums {
        if (num > fourth_largest) {
            fourth_largest = num;
        }
    }
    for _ in range(3) {
        max_value = float('-inf');
        for num in nums {
            if ((num > max_value) and (num < fourth_largest)) {
                max_value = num;
            }
        }
        fourth_largest = max_value;
    }
    return fourth_largest;
}



with entry {
    print(find_fourth_largest([-2, -1, 4, 7]));
}
