"""
Takes a scalar and returns a string with
the css property `'color: red'` for negative
strings, black otherwise.
"""
def col_shade(s: float | int | str) -> str {
    color = 'rgba(0,0,0,0.5)';
    return 'background-color: {}'.format(color);
}