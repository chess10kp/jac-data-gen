def contains_duplicates_iterative(lst: Any) -> object {
    n = len(lst);
    for i in range(n) {
        for j in range((i + 1), n) {
            if (lst[i] == lst[j]) {
                return True;
            }
        }
    }
    return False;
}



with entry {
    print(contains_duplicates_iterative('hello'));
    print(contains_duplicates_iterative([81]));
}
