"""
Returns a string representation of the ordinal number for `n`

e.g.,
>>> ordinal_number(1)
'1st'
>>> ordinal_number(4)
'4th'
>>> ordinal_number(21)
'21st'
"""
def ordinal_number(n: int) -> str {
    return '%d%s' % (n, 'tsnrhtdd'[((((n // 10) % 10) != 1) * ((n % 10) < 4) * (n % 10))::4]);
}