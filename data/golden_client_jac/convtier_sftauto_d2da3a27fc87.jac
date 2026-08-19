def get_largest_sum(num_list: Any) -> object {
    num_list.sort(reverse=True);
    return (num_list[0] + num_list[1]);
}



with entry {
    print(get_largest_sum([6, -12]));
    print(get_largest_sum([21, -3, -6, -12]));
}
