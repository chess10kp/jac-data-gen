import re;

"""It removes the ansi codes from a string."""
def escape_ansi(line: str) -> str {
    ansi_escape = re.compile(r'(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]');
    return ansi_escape.sub('', line);
}