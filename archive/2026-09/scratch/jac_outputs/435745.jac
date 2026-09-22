"""
Input: Two list of artists_id
Return two lists containing:
- Every artist in compared_artist_list that are in another_artists_list
- Every artist in compared_artist_list that are not in another_artists_list
"""
def separate_artists_list_by_comparing_with_another(
    another_artists_list: list[int], compared_artist_list: list[int]
) -> tuple[list[int], list[int]] {
    is_in_artist_list = [artist for artist in compared_artist_list if artist in another_artists_list];
    is_not_in_artist_list = [artist for artist in compared_artist_list if artist not in another_artists_list];
    return (is_in_artist_list, is_not_in_artist_list);
}