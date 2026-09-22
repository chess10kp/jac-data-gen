"""
    Gets the url for a page containing information for specified game from NHL API.

    :param season: int, the season
    :param game: int, the game

    :return: str, https://statsapi.web.nhl.com/api/v1/game/[season]0[game]/feed/live
    """
def get_game_url(season: Any, game: Any) -> object {
    return 'https://statsapi.web.nhl.com/api/v1/game/{0:d}0{1:d}/feed/live'.format(
        season, game
    );
}