def get_non_unique_elements(lst: Any) -> object {
    non_unique_elements = [];
    for i in range(len(lst)) {
        count = 0;
        for j in range(len(lst)) {
            if ((i != j) and (lst[i] == lst[j])) {
                count += 1;
            }
        }
        if ((count > 0) and (lst[i] not in non_unique_elements)) {
            non_unique_elements.append(lst[i]);
        }
    }
    return non_unique_elements;
}



with entry {
    print(get_non_unique_elements('hello'));
    print(get_non_unique_elements('Racecar'));
    print(get_non_unique_elements('abcabc'));
}
