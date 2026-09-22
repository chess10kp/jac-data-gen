"""energy divisor"""
def e_d(val: int) -> int | None {
    match val {
        case 0:
            return 10000;
        case 1:
            return 1000;
        case 2:
            return 100;
        case 3:
            return 10;
        case _:
            return None;
    }
}