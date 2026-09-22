"""Returns a formatted line of text describing the track."""
def format_track(index: int, data: dict[str, str]) -> str {
    "{}. {artist} - {album} - {track}\n".format(index, **data)
}