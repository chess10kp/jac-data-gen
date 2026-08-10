"""Based on player-account assigments this function returns 'screen_name' -> schedule player name mapping."""
def get_screen_name_to_player(players_dict: dict[str, list[str]]) -> dict[str, str] {
    screen_name_to_player = {};
    for player in players_dict {
        for screen_name in players_dict[player] {
            if screen_name in screen_name_to_player {
                raise RuntimeError(
                    "screen_name duplication for '%s' is note allowed!" % screen_name
                );
            }
            screen_name_to_player[screen_name] = player;
        }
    }
    return screen_name_to_player;
}