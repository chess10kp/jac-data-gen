def sum_of_unique_elements(lst: Any) -> object {
    unique_elements = `set(lst);
    return sum(unique_elements);
}



with entry {
    print(sum_of_unique_elements([]));
}
