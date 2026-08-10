"""Removes surrounding whitespace, surrounding \\emph brackets etc."""
def clean_bibitem_string(string: str) -> str {
    out = string;
    out = out.strip();
    if out[:6] == "\\emph{" and out[-1] == "}" {
        out = out[6:-1];
    }
    if out[:8] == "\\textsc{" and out[-1] == "}" {
        out = out[8:-1];
    }
    return out;
}