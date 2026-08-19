def transform_list_to_dict(nums: Any) -> object {
    unique_nums = sorted(`list(`set(nums)), reverse=True);
    result = {};
    for num in unique_nums {
        if ((num % 3) == 0) {
            result[num] = num ** 3;
        }
    }
    return result;
}



with entry {
    print(transform_list_to_dict([-9]));
    print(transform_list_to_dict([]));
    print(transform_list_to_dict([-8, -4, 2, 6]));
}
