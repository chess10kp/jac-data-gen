def are_all_elements_equal(lst: Any) -> object {
    if not lst {
        return True;
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
    print(are_all_elements_equal('hello'));
    print(are_all_elements_equal(0));
}
