"""UDF function to fix duplicate primary types."""
def clean_primary_types(val: str) -> str {
    if val in ("NON - CRIMINAL", "NON-CRIMINAL", "NON-CRIMINAL (SUBJECT SPECIFIED)") {
        return "NON-CRIMINAL";
    }
    if "NARCOTIC" in val {
        return "NARCOTICS";
    }
    return val;
}