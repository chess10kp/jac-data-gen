"""pseudo-paginate a document by creating lists of tokens of length `target-length` that overlap at 50%"""
def overlap(document_tokens: list[str], target_length: int) -> list[list[str]] {
    overlapped = [];
    cursor = 0;
    while len(' '.join(document_tokens[cursor:]).split()) >= target_length {
        overlapped.append(document_tokens[cursor:(cursor + target_length)]);
        cursor += target_length // 2;
    }
    return overlapped;
}