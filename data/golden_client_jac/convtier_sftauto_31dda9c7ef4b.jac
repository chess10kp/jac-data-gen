def powerset_with_duplicates(lst: Any) -> object {
    powerset = [[]];
    for num in lst {
        new_subsets = [];
        for subset in powerset {
            new_subset = subset + [num];
            new_subsets.append(new_subset);
        }
        powerset += new_subsets;
    }
    return powerset;
}



with entry {
    print(powerset_with_duplicates('hello'));
    print(powerset_with_duplicates('Racecar'));
    print(powerset_with_duplicates('abcabc'));
}
