def sort_numbers(nums: Any) -> object {
    temp_list = [];
    for num in nums {
        if (isinstance(num, int) and (num >= 5)) {
            temp_list.append(num);
        } elif isinstance(num, `list) {
            temp_list += sort_numbers(num);
        }
    }
    sorted_list = sorted(`set(temp_list), reverse=True);
    return sorted_list;
}



with entry {
    print(sort_numbers('hello'));
    print(sort_numbers([34]));
    print(sort_numbers([10, 20, 30]));
}
