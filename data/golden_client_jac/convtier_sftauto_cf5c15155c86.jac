def sumDigits(num: Any) -> object {
    if (num == 0) {
        return 0;
    } else {
        return ((num % 10) + sumDigits((num // 10)));
    }
}



with entry {
    print(sumDigits(0));
}
