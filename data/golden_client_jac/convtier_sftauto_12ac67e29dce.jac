def round_list(numbers: Any) -> object {
    return [round(num, 4) for num in numbers];
}



with entry {
    print(round_list([]));
}
