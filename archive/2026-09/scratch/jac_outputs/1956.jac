"""Preprocessing to strip tags in SGM files."""
def _preprocess_sgm(line: str, is_sgm: bool) -> str | None {
    if not is_sgm {
        return line;
    }
    if line.startswith(("<srcset", "</srcset")) {
        return "";
    }
    if line.startswith(("<refset", "</refset")) {
        return "";
    }
    if line.startswith(("<doc", "</doc")) {
        return "";
    }
    if line.startswith(("<p>", "</p>")) {
        return "";
    }
    line = line.strip();
    if line.startswith("<seg") and line.endswith("</seg>") {
        i = line.index(">");
        return line[(i + 1):-6];
    }
}