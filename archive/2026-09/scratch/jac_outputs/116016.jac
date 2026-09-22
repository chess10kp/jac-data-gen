"""
USAGE
-----
texstr = float2latex(f, ndigits=1)

Converts a float input into a latex-formatted
string with 'ndigits' (defaults to 1).

Adapted from:
http://stackoverflow.com/questions/13490292/format-number-using-latex-notation-in-python
"""
def float2latex(f: float, ndigits: int = 1) -> str {
    float_str = "{0:.%se}" % ndigits;
    float_str = float_str.format(f);
    (base, exponent) = float_str.split("e");
    return "${0} \times 10^{{{1}}}$".format(base, int(exponent));
}