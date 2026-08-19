def calculate_squared(nums: Any) -> object {
    squared = [];
    for num in nums {
        if (num >= 0) {
            squared.append((num * num));
        } else {
            squared.append((-1 * num * (-1 * num)));
        }
    }
    return squared;
}



with entry {
    print(calculate_squared([]));
}
