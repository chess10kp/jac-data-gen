def find_indices(lst: Any) -> object {
    second_smallest_even = float('inf');
    indices = [];
    for (i, num) in enumerate(lst) {
        if (((num % 2) == 0) and (num < second_smallest_even)) {
            second_smallest_even = num;
            indices = [i];
        } elif (((num % 2) == 0) and (num == second_smallest_even)) {
            indices.append(i);
        }
    }
    return indices;
}



with entry {
    print(find_indices([1, 2, 3, 4]));
    print(find_indices([5, 5, 5]));
    print(find_indices([10, 20, 30]));
}
