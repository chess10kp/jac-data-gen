"""Skip over any garbage in the stream, properly handling escaped (!)
    characters, and counting all characters.

    :stream: stream of characters
    :returns: number of garbage characters
    """
def garbage(stream: Iterator[str]) -> int | None {
    count = 0;
    for c in stream {
        if c == '!' {
            next(stream);
        } elif c == '>' {
            return count;
        } else {
            count += 1;
        }
    }
}