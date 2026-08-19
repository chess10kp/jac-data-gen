def find_missing_number(nums: Any) -> object {
    for i in range(1, (len(nums) + 2)) {
        if (i not in nums) {
            return i;
        }
    }
    return -1;
}



with entry {
    print(find_missing_number([]));
}
