"""Takes in a state and returns its parity (even = 0, odd = 1)."""
def calc_parity(state: str) -> int {
    bit_sum = 0;
    for bit in state {
        if int(bit) not in (0, 1) {
            raise ValueError('state {} not allowed'.format(state));
        }
        bit_sum += int(bit);
    }
    return bit_sum % 2;
}