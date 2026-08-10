"""Ignore the Deutscher Spielepreile Goodie Boxes and Brettspiel Adventskalender as expansions and treat them like base games"""
def is_promo_box(game: dict[str, list[dict[str, int]]]) -> bool {
    return `any(39378 == family["id"] for family in game["families"]);
}