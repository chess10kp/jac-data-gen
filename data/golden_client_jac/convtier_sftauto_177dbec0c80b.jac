def calculate_factorial(n: Any) -> object {
    if (n < 0) {
        raise FactorialError("Factorial can only be calculated for positive integers.");
    } elif ((n == 0) or (n == 1)) {
        return 1;
    } else {
        result = n * calculate_factorial((n - 1));
        if (result > (10 ** 9)) {
            raise FactorialError("Factorial exceeds the maximum limit of 10^9.");
        }
        return result;
    }
}



with entry {
    print(calculate_factorial(0));
}
