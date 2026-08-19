def sum_elements(my_list: Any) -> object {
    total = 0;
    for element in my_list {
        if isinstance(element, (int, float)) {
            total += element;
        }
    }
    return total;
}



with entry {
    print(sum_elements('hello'));
}
