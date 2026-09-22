"""
    Unest teams field from STEAM API
    """
def extract_teams(picks_bans: Any, radiant_win: Any) -> object {
    teams = {'winners': [], 'loosers': []};
    for pick_ban in picks_bans {
        if pick_ban['is_pick'] {
            is_win = pick_ban['team'] != radiant_win;
            teams['winners' if is_win else 'loosers'].append(pick_ban['hero_id']);
        }
    }
    for team in teams.keys() {
        teams[team].sort();
    }
    return teams;
}