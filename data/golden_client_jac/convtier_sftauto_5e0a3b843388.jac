def manipulate_list(lst: Any) -> object {
    doubled_lst = [(2 * x) for x in lst];
    n = len(doubled_lst);
    for i in range(n) {
        for j in range(0, (n - i - 1)) {
            if (doubled_lst[j] > doubled_lst[(j + 1)]) {
                (doubled_lst[j], doubled_lst[(j + 1)]) = (
                    doubled_lst[(j + 1)],
                    doubled_lst[j]
                );
            }
        }
    }
    return doubled_lst;
}



with entry {
    print(manipulate_list('hello'));
    print(manipulate_list('Racecar'));
    print(manipulate_list('abcabc'));
}
