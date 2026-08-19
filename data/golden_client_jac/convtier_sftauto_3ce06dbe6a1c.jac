def max_sum(arr: Any) -> object {
    incl = 0;
    excl = 0;
    for i in arr {
        new_excl = max(incl, excl);
        incl = excl + i;
        excl = new_excl;
    }
    return max(incl, excl);
}



with entry {
    print(max_sum([2, 9]));
    print(max_sum([2]));
    print(max_sum([34]));
}
