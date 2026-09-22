"""Converts n bits to a human readable format."""
def bits2human(n: int, format: str = "%(value).1f%(symbol)s") -> str {
    symbols = ('B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB');
    prefix: dict[str, int] = {};
    prefix['B'] = 8;
    for (i, s) in enumerate(symbols[1:]) {
        prefix[s] = (1024 ** (i + 1)) * 8;
    }
    for symbol in reversed(symbols) {
        if n >= prefix[symbol] {
            value = float(n) / prefix[symbol];
            return format % locals();
        }
    }
    return format % dict(symbol=symbols[0], value=n);
}