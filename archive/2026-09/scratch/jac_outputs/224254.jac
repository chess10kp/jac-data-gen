"""Check if a string is a hex-only string of exactly :param:`chars` characters length.
    This is useful to verify that a string contains a valid SHA, MD5 or UUID-like value.
    >>> _is_hex_str('0f1128046248f83dc9b9ab187e16fad0ff596128f1524d05a9a77c4ad932f10a', 64)
    True
    >>> _is_hex_str('0f1128046248f83dc9b9ab187e16fad0ff596128f1524d05a9a77c4ad932f10a', 32)
    False
    >>> _is_hex_str('0f1128046248f83dc9b9ab187e1xfad0ff596128f1524d05a9a77c4ad932f10a', 64)
    False
    >>> _is_hex_str('ef42bab1191da272f13935f78c401e3de0c11afb')
    True
    >>> _is_hex_str('ef42bab1191da272f13935f78c401e3de0c11afb'.upper())
    True
    >>> _is_hex_str('ef42bab1191da272f13935f78c401e3de0c11afb', 64)
    False
    >>> _is_hex_str('ef42bab1191da272f13935.78c401e3de0c11afb')
    False
    """
def _is_hex_str(value: Any, chars: Any = 40) -> object {
    if (len(value) != chars) {
        return False;
    }
    try {
        int(value, 16);
    } except ValueError {
        return False;
    }
    return True;
}