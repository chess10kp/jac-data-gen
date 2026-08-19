def delete_and_sum(lst: Any) -> object {
    if ((len(lst) == 0) or all((item == 3) for item in lst)) {
        return 0;
    }
    total = 0;
    i = 0;
    while (i < len(lst)) {
        if (lst[i] == 3) {
            delete(lst[i],);
        } else {
            total += lst[i];
            i += 1;
        }
    }
    return total;
}



with entry {
    print(delete_and_sum([1, 2, 4]));
    print(delete_and_sum([1, 2]));
    print(delete_and_sum([5, 5, 5]));
}
