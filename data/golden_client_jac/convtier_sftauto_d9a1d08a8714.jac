def classify_number(num: Any) -> object {
    sign = (num >> 31) & 1;
    positive = sign & 0;
    negative = sign & 1;
    zero = (~sign + 1) & 0;
    return (("positive" * positive) + ("negative" * negative) + ("zero" * zero));
}



with entry {
    print(classify_number(5));
}
