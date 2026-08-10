"""
    Check if number is Armstrong number
    """
def armstrong_number(number: int) -> bool {
    calc = number;
    sum_ = 0;
    while calc > 0 {
        dig = calc % 10;
        sum_ += dig ** 3;
        calc //= 10;
    }
    return number == sum_;
}