def nested_list_sum(lst: Any) -> object {
    total_sum = 0;
    for element in lst {
        if isinstance(element, `list) {
            total_sum += nested_list_sum(element);
        } elif (isinstance(element, int) or isinstance(element, float)) {
            total_sum += element;
        }
    }
    return total_sum;
}



with entry {
    print(nested_list_sum('hello'));
}
