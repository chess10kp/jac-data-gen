"""Escape the replacement pattern for a re.sub function."""
def re_sub_escape(pattern: str) -> str {
    return pattern.replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t").replace("\f", "\\f");
}