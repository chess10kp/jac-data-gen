def calculate_e(n: Any) -> object {
    if (n < 0) {
        return "Invalid input";
    } elif (n == 0) {
        return 1;
    } else {
        result = 1;
        factorial = 1;
        for i in range(1, (n + 1)) {
            factorial *= i;
            result += 1 / factorial;
        }
        return round(result, 4);
    }
}



with entry {
    print(calculate_e(5));
    print(calculate_e(10));
    print(calculate_e(2));
}
