def round_to_nearest_hundredth(num: Any) -> object {
    rounded_num = round(num, 2);
    return rounded_num;
}



with entry {
    print(round_to_nearest_hundredth(5));
    print(round_to_nearest_hundredth(10));
    print(round_to_nearest_hundredth(2));
}
