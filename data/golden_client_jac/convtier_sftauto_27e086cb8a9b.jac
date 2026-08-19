def initialize_list(start: Any) -> object {
    my_list = [];
    for num in range(start, (start + 100)) {
        if (((num % 3) != 0) or ((num % 4) != 0)) {
            my_list.append(num);
        }
    }
    return my_list;
}



with entry {
    print(initialize_list(5));
    print(initialize_list(10));
    print(initialize_list(2));
}
