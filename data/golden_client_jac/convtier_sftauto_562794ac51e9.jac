def is_sorted(lst: Any) -> object {
    for i in range((len(lst) - 1)) {
        if (lst[i] > lst[(i + 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_sorted('hello'));
    print(is_sorted([]));
}
