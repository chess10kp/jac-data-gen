"""Transform charges from float to string format."""
def manipulatePartialChargesTag(charges: list[float]) -> str {
    value = '';
    for charge in charges {
        value += str(charge) + '\n';
    }
    return value;
}