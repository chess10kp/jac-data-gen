"""Condition function to designate if issue should be archived."""
def to_be_archived(row: dict[str, str]) -> bool {
    return row["Priority"] == "Done";
}