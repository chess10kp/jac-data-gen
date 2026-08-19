def find_5th_largest(lst: Any) -> object {
    n = 5;
    sorted_list = sorted(lst, reverse=True);
    fifth_largest = sorted_list[(n - 1)];
    index = lst.index(fifth_largest);
    return index;
}



with entry {
    print(find_5th_largest('hello'));
    print(find_5th_largest('abcabc'));
    print(find_5th_largest('Hello, World!'));
}
