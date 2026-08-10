"""attempt to remove hidden hashtags at the bottom of captions"""
def remove_block_hashtags(caption: str) -> str {
    caption = caption.split('\n', 1)[0];
    clean_caption = caption.split('\u2022', 1)[0];
    return clean_caption.strip();
}