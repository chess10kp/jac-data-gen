def are_elements_unique(lst: Any) -> object {
    n = len(lst);
    unique_elements = `set();
    for i in range(n) {
        if (lst[i] in unique_elements) {
            return False;
        }
        unique_elements.add(lst[i]);
    }
    return True;
}



with entry {
    print(are_elements_unique('hello'));
    print(are_elements_unique([81]));
}
