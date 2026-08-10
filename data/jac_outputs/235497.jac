"""Capitalize the first letter of each word of a string. The remaining characters are untouched.

    Arguments:
        st {str} -- string to convert

    Returns:
        str -- converted string
    """
def capital_case(st: str) -> str {
    if (len(st) >= 1) {
        words = st.split();
        return ' '.join(
            [
                f'{s[:1].upper()}{s[1:]}'
                for s in words
                if (len(s) >= 1)
            ]
        );
    } else {
        return '';
    }
}