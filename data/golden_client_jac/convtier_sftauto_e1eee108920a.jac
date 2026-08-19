def sum_array(arr: Any) -> object {
    total = 0;
    for element in arr {
        if isinstance(element, int) {
            total += element;
        }
    }
    return total;
}



with entry {
    print(sum_array('hello'));
    print(sum_array([6, -12]));
}
