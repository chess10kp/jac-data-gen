"""Conversion binary -> decimal. Needed to calculate
    decimal variable value from binary coded genome."""
def bin_dec(bin: list[int | float]) -> float {
    dec = 0.0;
    bin.reverse();
    for (i, bit) in enumerate(bin) {
        dec += bit * (2 ** i);
    }
    return dec;
}