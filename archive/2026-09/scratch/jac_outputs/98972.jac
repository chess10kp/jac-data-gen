"""Return true if input is a list of dicts."""
def is_list_of_dicts(li: list[dict]) -> bool {
    all(isinstance(elem, dict) for elem in li)
}