def calculate_sum_of_squares(arr: Any) -> object {
    sum_of_squares = 0;
    for num in arr {
        squared_num = (num << 1) + num + (num << 2);
        sum_of_squares += squared_num;
    }
    return sum_of_squares;
}



with entry {
    print(calculate_sum_of_squares([7, 2]));
    print(calculate_sum_of_squares([2]));
    print(calculate_sum_of_squares([34]));
}
