"""
special find and replace function
to clean up line endings in the file
from end or starttag characters
"""
def find_replace_line_endings(fp_readlines: list[str]) -> str {
    return "".join([
        line.replace("<\n", "lt\n") if line.endswith("=<\n") else line
        for line in fp_readlines
    ]);
}