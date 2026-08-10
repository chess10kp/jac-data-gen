"""Return True if each str in list_expected_strs is in list_actual_strs."""
def verify_expected_list(list_expected_strs: list[str], list_actual_strs: list[str]) -> bool {
    return all(elem in list_actual_strs for elem in list_expected_strs);
}