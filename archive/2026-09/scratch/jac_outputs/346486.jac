"""Helper to format a dictionary into an ebuild file."""
def _dict_to_ebuild(dictionary: dict[str, str]) -> str {
    output = [('%s="%s"' % (key, dictionary[key])) for key in sorted(dictionary.keys())];
    output.append('\n');
    return '\n'.join(output);
}