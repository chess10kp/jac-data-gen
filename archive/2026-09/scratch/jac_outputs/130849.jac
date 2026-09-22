"""returns the percentage of wins"""
def win_percent(num_games: Any, game_wins: Any) -> object {
    total_games = num_games;
    win_percents = game_wins[:];
    for i in range(0, len(win_percents)) {
        win_percents[i] = round(((1.0 * game_wins[i]) / (total_games * 1.0)), 2);
    }
    return win_percents;
}