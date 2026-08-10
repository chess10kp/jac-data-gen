"""Convert an ICD9 code from major/minor parts to decimal format."""
def parts_to_decimal(major: str, minor: str) -> str {
    if major[0] in ("V", "E") {
        major = major[0] + major[1:].lstrip("0");
        if len(major) == 1 {
            major = major + "0";
        }
    } else {
        major = major.lstrip("0");
        if len(major) == 0 {
            major = "0";
        }
    }
    major + "." + minor
}