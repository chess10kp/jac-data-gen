"""Here we just remove every consecutive duplicate tokens, so we only track changes
    e.g text ABC ABC ABC EE A S X X SD will be compressed to:
            ABC EE A S X SD."""
def lossy_compresion(text: str, token_separator: str = " ") -> str {
    compressed = [];
    tokenized = text.split(token_separator);
    previous = None;
    for token in tokenized {
        if token != previous {
            compressed.append(token);
            previous = token;
        }
    }
    return " ".join(compressed);
}