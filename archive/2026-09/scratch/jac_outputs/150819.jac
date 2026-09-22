"""Prime Factorization"""
def problem3(number: Any) -> object {
    i = 2;
    while ((i * i) < number) {
        while ((number % i) == 0) {
            number /= i;
        }
        i += 1;
    }
    return int(number);
}