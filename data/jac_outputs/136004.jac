"""Determines if all elements of the address set are in the column map"""
def _address_set_in_column_map(address_set: tuple[int, ...], column_map: list[int]) -> bool {
    return all(element in column_map for element in address_set);
}