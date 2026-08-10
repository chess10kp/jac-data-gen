"""splituser('user[:passwd]@host[:port]') --> 'user[:passwd]', 'host[:port]'."""
def splituser(host: str) -> tuple[str | None, str] {
    (user, delim, host) = host.rpartition('@');
    return (user if delim else None, host);
}