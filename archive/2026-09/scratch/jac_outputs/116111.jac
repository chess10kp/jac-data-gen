"""Removes unnecessary empty lines in text"""
def cleanup_double_endline(text: str) -> str {
    return text.replace('\n\n\n', '\n');
}