"""
    return farm ids that the given username has rented before
    """
def check_rent_history(rent_list: list[dict[str, str | int]], username: str) -> list[str] {
    [str(rent.get('farm_id')) for rent in rent_list if rent.get('username') == username]
}