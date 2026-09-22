"""Create version string."""
def versionString(version: list[int]) -> str {
    ver = [str(v) for v in version];
    (numbers, rest) = (ver[:2 if ver[2] == '0' else 3], ver[3:]);
    return '.'.join(numbers) + '-'.join(rest);
}