def find_maximum_number(lst: Any) -> object {
    if (len(lst) == 0) {
        return "Error: List is empty";
    }
    max_num = float('-inf');
    for num in lst {
        if (num > max_num) {
            max_num = num;
        }
    }
    return max_num;
}



with entry {
    print(find_maximum_number([81]));
    print(find_maximum_number([]));
    print(find_maximum_number([100]));
}
