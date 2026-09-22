def two_strings(s1: str, s2: str) -> str {
    intersection = {*s1} & {*s2};
    return "YES" if intersection else "NO";
}