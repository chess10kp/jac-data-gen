import re;

"""Returns the number of a numbered object. For example: "Frame 3", "Frame3", "Fram3 3" returns 3."""
def name_2_id(str_name_id: str) -> float | int {
    numbers = re.findall(r'[0-9]+', str_name_id);
    if len(numbers) > 0 {
        return float(numbers[-1]);
    }
    return -1;
}