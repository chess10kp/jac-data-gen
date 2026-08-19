def process_list(numbers: Any) -> object {
    result = [
        (x ** 2)
        for x in numbers
        if (((x % 2) == 0) and ((x % 3) != 0))
    ];
    result.sort(reverse=True);
    return result;
}



with entry {
    print(process_list([-9]));
    print(process_list([10, 20]));
    print(process_list([-8, -4, 2, 6]));
}
