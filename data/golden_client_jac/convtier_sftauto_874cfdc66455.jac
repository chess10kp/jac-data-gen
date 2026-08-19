def sumOfDigits(num: Any) -> object {
    if (num <= 0) {
        return 0;
    }
    digit = num % 10;
    if ((digit % 3) == 0) {
        return sumOfDigits((num // 10));
    } else {
        return (digit + sumOfDigits((num // 10)));
    }
}



with entry {
    print(sumOfDigits(0));
}
