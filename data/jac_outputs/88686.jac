"""Merge each paragraph of line-wrapped text onto a single line."""
def dealign(text: str) -> str {
    original_lines = text.splitlines();
    paragraphs = [];
    i = 0;
    while i < len(original_lines) {
        paragraph_lines = [];
        while True {
            line = original_lines[i];
            i += 1;
            if line {
                paragraph_lines.append(line);
            }
            if not line or i == len(original_lines) {
                if paragraph_lines {
                    paragraphs.append(' '.join(paragraph_lines));
                }
                break;
            }
        }
        if i == len(original_lines) {
            break;
        }
    }
    return '\n'.join(paragraphs);
}