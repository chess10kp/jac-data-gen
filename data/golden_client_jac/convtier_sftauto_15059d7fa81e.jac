def find_smallest_positive_number(nums: Any) -> object {
    num_set = `set();
    for num in nums {
        if (num > 0) {
            num_set.add(num);
        }
    }
    smallest_positive = 1;
    while (smallest_positive in num_set) {
        smallest_positive += 1;
    }
    return smallest_positive;
}



with entry {
    print(find_smallest_positive_number([81]));
}
