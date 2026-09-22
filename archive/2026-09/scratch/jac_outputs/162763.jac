"""Get the number of games contained in the specified json data."""
def get_games_count(json_data: dict[str, int | str]) -> int {
    total_games = 0;
    if 'totalGames' in json_data {
        total_games = int(json_data['totalGames']);
    }
    return total_games;
}