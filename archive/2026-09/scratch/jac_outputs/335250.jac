"""Convert a list of dictionaries to Perl-style syntax. Uses
string-replace so rather brittle."""
def to_perl_syntax(d: list[dict[str, object]]) -> str {
    return str(d).replace(':', ' => ').replace('[', '(').replace(']', ')');
}