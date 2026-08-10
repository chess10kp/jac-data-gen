"""Builds a locale code from the given tuple (language code, encoding)."""
def _build_localename(localetuple: tuple[str | None, str | None]) -> str {
    try {
        (language, encoding) = localetuple;
        if language is None {
            language = 'C';
        }
        if encoding is None {
            return language;
        }
        return language + '.' + encoding;
    } except (TypeError, ValueError) {
        raise TypeError(
            'Locale must be None, a string, or an iterable of two strings -- language code, encoding.'
        );
    }
}