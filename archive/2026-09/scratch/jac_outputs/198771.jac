"""Return total arrangement quantity for the given letter count."""
def factorial(letter_qty: int) -> int {
    if letter_qty == 0 {
        return 1;
    }
    return letter_qty * factorial(letter_qty - 1);
}