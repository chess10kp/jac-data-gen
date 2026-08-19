def check_divisibility(num: Any) -> object {
    if (((num % 7) == 0) and ((num % 13) == 0) and ((num % 5) != 0)) {
        return True;
    } else {
        return False;
    }
}



with entry {
    print(check_divisibility(5));
}
