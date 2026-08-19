def are_elements_unique(lst: Any) -> object {
    for i in range((len(lst) - 1)) {
        for j in range((i + 1), len(lst)) {
            if (lst[i] == lst[j]) {
                return False;
            }
        }
    }
    return True;
}



with entry {
    print(are_elements_unique('hello'));
    print(are_elements_unique([]));
}
