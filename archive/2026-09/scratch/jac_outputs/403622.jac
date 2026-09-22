"""
    Helper function used to find offensive plays in possible plays.
    :param possible_plays: list of cards possible to be played
    :return: list of cards which can be played as attack
    """
def find_offensive_plays(possible_plays: list[tuple[str, str]]) -> list[tuple[str, str]] {
    return [
        card for card in possible_plays
        if card in (('pikes', 'K'), ('hearts', 'K')) or card[1] in '2 3 4 J'.split()
    ];
}