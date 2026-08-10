class HasSpotifyId(Protocol) {
    def spotify_id -> str;
}

"""Turn a list of objects into a list of spotify ids."""
def map_ids(elems: list[HasSpotifyId]) -> list[str] {
    [elem.spotify_id() for elem in elems]
}