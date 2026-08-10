"""Builds a dictionary describing a music album"""
def make_album(artist_name: str, album_title: str, num_of_songs: int | None = None) -> dict[str, str | int] {
    album: dict[str, str | int] = {'Artist': artist_name.title(), 'Album': album_title.title()};
    if num_of_songs {
        album['num_of_songs'] = num_of_songs;
    }
    return album;
}