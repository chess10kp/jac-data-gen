"""
Converts the GitHub Link header to a dict.

Example::

>>> link2dict('<https://api.github.com/repos/sympy/sympy/pulls?page=2&state=closed>; rel="next",  <https://api.github.com/repos/sympy/sympy/pulls?page=21&state=closed>; rel="last"')
{'last': 'https://api.github.com/repos/sympy/sympy/pulls?page=21&state=closed',  'next': 'https://api.github.com/repos/sympy/sympy/pulls?page=2&state=closed'}
"""
def _link2dict(l: str) -> dict[str, str] {
    d: dict[str, str] = {};
    while True {
        i = l.find(";");
        assert i != -1;
        assert l[0] == "<";
        url = l[1:(i - 1)];
        assert l[(i - 1)] == ">";
        assert l[(i + 1):(i + 7)] == ' rel="';
        j = l.find('"', (i + 7));
        assert j != -1;
        param = l[(i + 7):j];
        d[param] = url;
        if len(l) == (j + 1) {
            break;
        }
        assert l[(j + 1)] == ",";
        j += 2;
        l = l[(j + 1):];
    }
    return d;
}