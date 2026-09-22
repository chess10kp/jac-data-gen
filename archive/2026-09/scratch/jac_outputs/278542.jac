"""Find and return seat numbers that are unassigned."""
def find_all_available_seats(seats: dict[int, object | None]) -> list[int] {
    return [seat_num for (seat_num, value) in seats.items() if value is None];
}