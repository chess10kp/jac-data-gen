"""Return the full name of an Override Audit syntax based on the short name."""
def oa_syntax(file: str) -> str {
    return "Packages/OverrideAudit/syntax/%s.sublime-syntax" % file;
}