def find_minimum(lst: Any) -> object {
    if (len(lst) == 1) {
        return lst[0];
    } else {
        return min(lst[0], find_minimum(lst[1:]));
    }
}



with entry {
    print(find_minimum([81]));
    print(find_minimum(['a']));
    print(find_minimum([100]));
}
