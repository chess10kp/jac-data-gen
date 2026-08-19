def repeat_last_two(string: Any) -> object {
    if (len(string) == 2) {
        return (string[::-1] * 2);
    }
    return (repeat_last_two(string[:-1]) + string[-1]);
}



with entry {
    print(repeat_last_two([2, 9]));
}
