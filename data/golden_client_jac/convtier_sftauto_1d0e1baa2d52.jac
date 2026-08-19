def calculate_factorial(x: Any) -> object {
    if (x < 0) {
        return "Error: Factorials are only defined for non-negative integers.";
    } elif (x == 0) {
        return 1;
    } else {
        return (x * calculate_factorial((x - 1)));
    }
}



with entry {
    print(calculate_factorial(0));
}
