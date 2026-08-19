def get_unique_elements(nums: Any) -> object {
    unique_elements = [];
    for i in range(len(nums)) {
        is_unique = True;
        for j in range((i + 1), len(nums)) {
            if (nums[i] == nums[j]) {
                is_unique = False;
                break;
            }
        }
        if is_unique {
            unique_elements.append(nums[i]);
        }
    }
    return unique_elements;
}



with entry {
    print(get_unique_elements('hello'));
    print(get_unique_elements('Racecar'));
    print(get_unique_elements('abcabc'));
}
