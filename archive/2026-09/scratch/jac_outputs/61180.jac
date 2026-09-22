"""One hot encode."""
def one_hot_encode(integer_encoding: int, num_classes: int) -> list[int] {
    onehot_encoded = [0 for _ in range(num_classes)];
    onehot_encoded[integer_encoding] = 1;
    return onehot_encoded;
}