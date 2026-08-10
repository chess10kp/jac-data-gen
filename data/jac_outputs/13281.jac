"""Clean extra info from music name."""
def clean_music_name(music_name: str) -> str {
    breaking_substring_list = [' (feat.', ' (with'];
    for substring in breaking_substring_list {
        if substring in music_name {
            breaking_point = music_name.find(substring);
            music_name = music_name[:breaking_point];
        }
    }
    return music_name;
}