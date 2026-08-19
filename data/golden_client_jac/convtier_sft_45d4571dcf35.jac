def signature_phrase(signatures: int) -> str {
    return f"{signatures} signature{'s' if signatures != 1 else ''}";
}

with entry {
    print(signature_phrase(1));
}
