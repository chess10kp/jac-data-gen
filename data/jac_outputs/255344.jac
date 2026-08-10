"""
    Split a long form name like "Derrick J Schommer" into "Derrick" and "J Schommer".

    The Shopify system uses one long name field, where WooCommerce uses 2 fields for
    first and last name (and we'll just stuff all the extra letters into the second field
    if they have middle initials, or are a Jr. or III, etc.)

    Parameters
    ----------
    name: The name of the customer like "Derrick Schommer" or "Derrick J Schommer III"

    Returns
    -------
    str, str : returns two strings, the first name and the rest (as last name)
    """
def split_name(name: str) -> tuple[str, str] {
    first_name = "";
    last_name = "";
    name_array = name.split(" ");
    first_name = name_array[0];
    if len(name_array) > 1 {
        name_array.pop(0);
        last_name = ' '.join(name_array);
    }
    return (first_name, last_name);
}