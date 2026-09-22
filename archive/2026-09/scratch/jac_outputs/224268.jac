"""Return true if first two numbers are 34 or 37"""
def is_amex(card_num: str) -> bool {
    return int(card_num[:2]) in (34, 37);
}