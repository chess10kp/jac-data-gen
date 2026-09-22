"""
    Returns a dictionary of split columns
    Used for amenities and host verifications within get_cleaned_listings()

    :params input_val array:
    :params split_by_char string:
    :params enclosure_char string:
    :params strip_char string:
    :params also_remove_single_inv_comma boolean(optional):
    :returns dictionary of split columns
    """
def clean_and_split(
    input_val: Any,
    split_by_char: Any = ',',
    enclosure_char: Any = '{|}|[|]',
    strip_chars: Any = '"',
    also_remove_single_inv_comma: Any = False
) -> object {
    input_val = input_val.strip();
    input_val = input_val.strip(enclosure_char);
    input_val = input_val.split(split_by_char);
    if (also_remove_single_inv_comma is True) {
        input_val = [
            item.strip().strip(strip_chars).strip("'").strip() for item in input_val
        ];
    } else {
        input_val = [item.strip().strip(strip_chars).strip() for item in input_val];
    }
    output_dict = {};
    for item in input_val {
        output_dict[item] = 1;
    }
    return output_dict;
}