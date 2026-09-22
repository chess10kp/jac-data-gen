"""Reverse the odd_flag list from the encoder."""
def get_odd_flags(odd_flags: list[list[bool]], blocks: list[list[bool]], flag_input: bool = False) -> list[list[bool]] {
    odd_list = [flag_input];
    for odd_block in odd_flags {
        odd_list += odd_block;
    }
    odd_list.reverse();
    odd_de = blocks.copy();
    i = 0;
    for (m, odd_block) in enumerate(odd_de) {
        odd_de[m] = blocks[m].copy();
        for (n, _) in enumerate(odd_block) {
            odd_de[m][n] = odd_list[i + 1];
            i += 1;
        }
    }
    return odd_de;
}