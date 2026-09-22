"""
    Convert English month name to a number from 1 to 12.
    """
def to_month_number(month_name: str) -> int {
    names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    if month_name in names {
        return names.index(month_name) + 1;
    }
    return 0;
}