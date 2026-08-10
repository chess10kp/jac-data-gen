"""Function to get player identifier and marker"""
def get_player_details(curr_player: Any) -> object {
    if (curr_player == 'A') {
        return ['B', 'O'];
    } else {
        return ['A', 'X'];
    }
}