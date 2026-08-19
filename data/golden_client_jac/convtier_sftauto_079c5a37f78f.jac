def square_odd_numbers(input_list: Any) -> object {
    squared_list = [];
    seen = `set();
    for num in input_list {
        if ((num % 2) != 0) {
            if (num not in seen) {
                squared_list.append((num ** 2));
                seen.add(num);
            }
        }
    }
    return squared_list;
}



with entry {
    print(square_odd_numbers([81]));
    print(square_odd_numbers([]));
    print(square_odd_numbers([-2, -1, 4, 7]));
}
