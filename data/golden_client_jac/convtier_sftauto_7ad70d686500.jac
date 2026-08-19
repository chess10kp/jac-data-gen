def check_number(n: Any) -> object {
    if ((n > 0) and ((n % 2) == 0)) {
        return "positive";
    } elif ((n < 0) and ((n % 2) != 0)) {
        return "negative";
    } elif (n == 0) {
        return "zero";
    } else {
        return "unknown";
    }
}



with entry {
    print(check_number(5));
    print(check_number(10));
    print(check_number(0));
}
