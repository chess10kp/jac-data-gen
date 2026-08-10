"""Check if .mp3 extension is present"""
def have_mp3_extension(l: str | list[str] | dict[str, str] | int | float) -> int {
    return 1 if ".mp3" in str(l) else 0;
}