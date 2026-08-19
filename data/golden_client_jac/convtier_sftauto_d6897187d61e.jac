def sumToN(n: Any) -> object {
    sum = 0;
    for i in range(1, (n + 1)) {
        if ((i % 2) == 0) {
            sum += i;
        }
    }
    return sum;
}



with entry {
    print(sumToN(5));
    print(sumToN(10));
    print(sumToN(2));
}
