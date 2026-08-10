"""Sort the list of donors by total amount donated.
    Returns a list of only the donors' names.
    """
def sort_donors(donor_dict: dict[str, list[float]]) -> list[str] {
    return sorted(list(donor_dict), key=lambda (x: str) { -sum(donor_dict[x]); });
}