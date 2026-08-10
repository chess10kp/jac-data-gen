"""Receive a comma-separated facility id string and return each id as a list element."""
def facilityidstringtolist(facilityidstring: str) -> list[str] {
    facilityidstring.split(",")
}