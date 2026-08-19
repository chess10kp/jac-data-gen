def absolute_value(num: Any) -> object {
    if (num < 0) {
        return (-1 * num);
    } else {
        return num;
    }
}



with entry {
    print(absolute_value(5));
    print(absolute_value(10));
    print(absolute_value(2));
}
