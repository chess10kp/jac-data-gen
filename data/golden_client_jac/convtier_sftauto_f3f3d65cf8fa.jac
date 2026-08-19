def remove_even_duplicates(lst: Any) -> object {
    odd_set = `set();
    for num in lst {
        if ((num % 2) != 0) {
            odd_set.add(num);
        }
    }
    return `list(odd_set);
}



with entry {
    print(remove_even_duplicates([0]));
    print(remove_even_duplicates([7, -1, -4, -2]));
}
