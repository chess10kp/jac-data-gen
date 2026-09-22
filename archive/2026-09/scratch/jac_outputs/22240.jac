"""get position embedding of x"""
def pos_embed(x: int, position_num: int) -> int {
    maxlen = int(position_num / 2);
    return max(0, min(x + maxlen, position_num));
}