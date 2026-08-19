def is_leap_year(year: Any) -> object {
    if ((year % 4) != 0) {
        return False;
    } elif ((year % 100) != 0) {
        return True;
    } elif ((year % 400) != 0) {
        return False;
    } else {
        return True;
    }
}



with entry {
    print(is_leap_year(5));
    print(is_leap_year(0));
}
