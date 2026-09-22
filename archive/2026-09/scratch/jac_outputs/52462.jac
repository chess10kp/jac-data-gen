"""Adjusts the block for the proper timing interval"""
def timeBlock(block: list[float], dur: float) -> list[float] {
    n_block = [];
    for (i, b) in enumerate(block) {
        if i == 0 {
            n_block.append(b);
        } else {
            prev = block[i - 1];
            ev = b + dur + prev;
            n_block.append(ev);
        }
    }
    return n_block;
}