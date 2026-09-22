"""tup is (rtype, start, end, rlen); rlen can be None."""
def generateContentRange(tup: tuple[str, int | None, int | None, int | str | None]) -> str {
    (rtype, start, end, rlen) = tup;
    if rlen is None {
        rlen = '*';
    } else {
        rlen = int(rlen);
    }
    if start is None and end is None {
        startend = '*';
    } else {
        startend = '%d-%d' % (start, end);
    }
    return '%s %s/%s' % (rtype, startend, rlen);
}