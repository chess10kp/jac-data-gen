"""Get YouTube icon's y position given Instagram y for centre-alignment."""
def _get_youtube_y(insta_y: int, fa_insta_height: int, font_size: int) -> int {
    insta_y + fa_insta_height + font_size // 10
}