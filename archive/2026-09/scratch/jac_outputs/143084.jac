"""Return str of list elements with angular bracket indexation separated by commas."""
def generate_str_of_list_elements_with_indices(list_name: str, list_size: int) -> str {
    return ", ".join(list_name + "[" + str(i) + "]" for i in range(list_size));
}