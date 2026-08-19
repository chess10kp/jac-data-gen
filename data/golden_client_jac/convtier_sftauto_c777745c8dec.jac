def sort_and_sum(lst: List[int]) -> int {
    unique_set = `set(lst);
    unique_set = {
        x
        for x in unique_set
        if (x > 1)
    };
    sorted_set = sorted(unique_set, reverse=True);
    sum_of_set = sum(sorted_set);
    return sum_of_set;
}



with entry {
    print(sort_and_sum([1, 2, 4]));
    print(sort_and_sum([1, 2]));
    print(sort_and_sum([5, 5, 5]));
}
