def count_unique_elements(lst: Any) -> object {
    lst.sort();
    count = 1;
    for i in range(1, len(lst)) {
        if (lst[i] != lst[(i - 1)]) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_unique_elements([1, 2, 4]));
    print(count_unique_elements([1, 2]));
    print(count_unique_elements([5, 5, 5]));
}
