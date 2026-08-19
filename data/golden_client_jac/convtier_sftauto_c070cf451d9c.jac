def transform_list(lst: Any) -> object {
    transformed_lst = [];
    for num in lst {
        if ((num % 2) == 0) {
            transformed_lst.append((num * 3));
        } else {
            transformed_lst.append(round(math.sqrt(num)));
        }
    }
    return transformed_lst;
}



with entry {
    print(transform_list([]));
    print(transform_list([100]));
    print(transform_list([-8, -4, 2]));
}
