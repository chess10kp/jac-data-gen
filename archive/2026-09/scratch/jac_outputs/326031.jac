"""Convert 0/1 or True/False to 'yes'/'no' strings."""
def yesno(value: int | bool) -> str {
    if value == 1 or value == True {
        return 'yes';
    }
    return 'no';
}