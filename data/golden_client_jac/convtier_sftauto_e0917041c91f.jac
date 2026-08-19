def remainder(num: Any) -> object {
    if (num < 4) {
        return num;
    } else {
        return remainder((num - 4));
    }
}



with entry {
    print(remainder(2));
    print(remainder(0));
    print(remainder(1));
}
