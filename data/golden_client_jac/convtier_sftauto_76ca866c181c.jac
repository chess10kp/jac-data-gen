def check_all_equal(lst: Any) -> object {
    if (len(lst) == 0) {
        return False;
    }
    first_element = lst[0];
    for element in lst {
        if (element != first_element) {
            return False;
        }
    }
    return True;
}



with entry {
    print(check_all_equal('hello'));
    print(check_all_equal([81]));
}
