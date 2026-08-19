def find_largest_number(lst: Any) -> object {
    if not lst {
        return "Error: List cannot be empty.";
    }
    lst = [
        int(num)
        for num in lst
        if (num >= 0)
    ];
    if not lst {
        return "Error: Negative numbers are not allowed.";
    }
    largest_num = max(lst);
    return largest_num;
}



with entry {
    print(find_largest_number(0));
    print(find_largest_number([81]));
    print(find_largest_number([100]));
}
