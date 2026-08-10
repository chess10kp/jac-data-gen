"""
    Gets the url for a page containing information for specified player from NHL API.

    :param playerid: int, the player ID

    :return: str, https://statsapi.web.nhl.com/api/v1/people/[playerid]
    """
def get_player_url(playerid: Any) -> object {
    return 'https://statsapi.web.nhl.com/api/v1/people/{0:s}'.format(str(playerid));
}