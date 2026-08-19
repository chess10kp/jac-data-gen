def is_leap_year(year: Any) -> object {
    if ((year % 4) == 0) {
        if ((year % 100) == 0) {
            if ((year % 400) == 0) {
                return True;
            } else {
                return False;
            }
        } else {
            return True;
        }
    } else {
        return False;
    }
}



with entry {
    print(is_leap_year(5));
    print(is_leap_year(0));
}
