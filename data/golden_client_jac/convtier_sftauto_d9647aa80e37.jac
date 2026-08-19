def sort_list(my_list: Any) -> object {
    sorted_list = [];
    while my_list {
        smallest = my_list[0];
        for num in my_list {
            if (num < smallest) {
                smallest = num;
            }
        }
        sorted_list.append(smallest);
        my_list.remove(smallest);
    }
    return sorted_list;
}



with entry {
    print(sort_list(0));
}
