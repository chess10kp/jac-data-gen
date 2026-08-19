def find_even_indexes(lst: Any) -> object {
    even_indexes = [];
    for i in range(len(lst)) {
        if ((i % 2) == 0) {
            even_indexes.append(lst[i]);
        }
    }
    return even_indexes;
}



with entry {
    print(find_even_indexes('hello'));
    print(find_even_indexes('Racecar'));
    print(find_even_indexes('abcabc'));
}
