"""One hot encode the three classes of rainfall."""
def one_hot_encode(x: int) -> list[int] | None {
    match x {
        case 0:
            return [1, 0, 0];
        case 1:
            return [0, 1, 0];
        case 2:
            return [0, 0, 1];
    }
}