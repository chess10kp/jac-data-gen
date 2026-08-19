def remove_duplicates(lst: Any) -> object {
    n = len(lst);
    i = 0;
    while (i < n) {
        j = i + 1;
        while (j < n) {
            if (lst[i] == lst[j]) {
                lst.pop(j);
                n -= 1;
            } else {
                j += 1;
            }
        }
        i += 1;
    }
    return lst;
}



with entry {
    print(remove_duplicates([-9]));
    print(remove_duplicates([]));
    print(remove_duplicates(['a']));
}
