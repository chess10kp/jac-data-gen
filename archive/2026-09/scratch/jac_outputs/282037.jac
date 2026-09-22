"""Generate an RFC 822 from-address string."""
def parse_fromaddr(fromaddr: str | tuple[str, str]) -> str {
    if isinstance(fromaddr, tuple) {
        fromaddr = "%s <%s>" % fromaddr;
    }
    return fromaddr;
}