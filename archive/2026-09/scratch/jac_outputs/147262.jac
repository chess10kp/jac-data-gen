"""Calculate the number of grains on the given chessboard square."""
def square(number: int) -> int {
    if not 1 <= number <= 64 {
        raise ValueError("square must be between 1 and 64");
    }
    return 1 << (number - 1);
}