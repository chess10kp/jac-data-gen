"""Returns the lyrics of a song arranged by the song data."""
def arrange_lyrics(arrangement: list[str], song_data: dict[str, dict[str, str]]) -> str {
    arranged_lyrics = "";
    for a in arrangement {
        arranged_lyrics += song_data["lyrics"][a];
        arranged_lyrics += "\n\n";
    }
    return arranged_lyrics;
}