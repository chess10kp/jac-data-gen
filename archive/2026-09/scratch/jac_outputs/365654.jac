"""Converting a CamelCase string to non_camel_case"""
def from_camel(string: str) -> str {
    assert isinstance(string, str) , 'string must be a type of `str`';
    out = '';
    for (i, c) in enumerate(string) {
        addition = c.lower();
        if c.isupper() {
            if (i != 0) {
                addition = '_' + addition;
            }
        }
        out += addition;
    }
    return out;
}