def powers_of_two(n: Any) -> object {
    if (n == 0) {
        return [1];
    } else {
        prev_powers = powers_of_two((n - 1));
        current_power = prev_powers[-1] * 2;
        return (prev_powers + [current_power]);
    }
}



with entry {
    print(powers_of_two(0));
}
