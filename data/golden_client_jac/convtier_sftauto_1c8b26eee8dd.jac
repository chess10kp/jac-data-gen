def check_divisibility(num: Any) -> object {
    if (((num % 7) == 0) and ((num % 13) == 0)) {
        for i in range(2, 101) {
            if ((num % i) == 0) {
                return False;
            }
        }
        return True;
    }
    return False;
}



with entry {
    print(check_divisibility(5));
}
