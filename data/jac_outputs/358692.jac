"""Compute quota needed based on total votes and number of seats."""
def get_threshold(votes: int, seats: int) -> int {
    return int(votes / (seats + 1)) + 1;
}