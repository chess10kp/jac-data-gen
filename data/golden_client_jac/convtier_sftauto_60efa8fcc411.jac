def is_power_of_three(n: Any) -> object {
    if (n <= 0) {
        return False;
    }
    power = math.log(n, 3);
    return ((3 ** round(power)) == n);
}



with entry {
    print(is_power_of_three(0));
}
