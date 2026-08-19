def sum_of_integers(lst: Any) -> object {
    integers = `list(`set(map(int, lst)));
    total = sum(integers);
    if (total < 2) {
        return False;
    }
    for i in range(2, (int((total ** 0.5)) + 1)) {
        if ((total % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(sum_of_integers([81]));
}
