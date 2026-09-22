"""
    This function helps to convert date information for showing proper filtering
    """
def grv(struct: dict[str, list], position: str) -> str {
    size = 4 if position == "year" else 2;
    if struct[position][2] {
        return str(struct[position][0]).zfill(size);
    }
    return "____" if position == "year" else "__";
}