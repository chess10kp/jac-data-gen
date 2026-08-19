def is_divisible_by_2_and_3(num: Any) -> object {
    if (((num & 1) == 0) and ((num % 3) == 0)) {
        return True;
    }
    return False;
}



with entry {
    print(is_divisible_by_2_and_3(5));
    print(is_divisible_by_2_and_3(0));
}
