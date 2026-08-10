"""
Removes the last updated ... line from html file and the data line from svg and then computes a hash.
"""
def file_hash(text: str) -> int {
    lines = text.split('\n');
    lines = [
        t
        for t in lines
        if not any(
            t.startswith(prefix)
            for prefix in ('  This website is built ', '    <dc:date>')
        )
    ];
    return hash(''.join(lines));
}