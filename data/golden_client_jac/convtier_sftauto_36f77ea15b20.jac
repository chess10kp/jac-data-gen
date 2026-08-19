def add_numbers(list_of_numbers: Any) -> object {
    total = 0;
    for num in list_of_numbers {
        if (num >= 0) {
            while (num != 0) {
                total += 1;
                num -= 1;
            }
        } else {
            while (num != 0) {
                total -= 1;
                num += 1;
            }
        }
    }
    return total;
}



with entry {
    print(add_numbers([]));
}
