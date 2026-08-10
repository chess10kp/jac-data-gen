"""Finds if there are any inferred properties which are used.

    Args:
      spec_dict: Dict obj containing configurations for the import.

    Returns:
      List of properties that appear in inferredSpec but are not part of 'pvs' section.
  """
def find_extra_inferred_properties(spec_dict: dict[str, list[str] | dict[str, str]]) -> list[str] {
    ret_list = [];
    if 'inferredSpec' in spec_dict {
        for property_name in spec_dict['inferredSpec'] {
            if property_name not in spec_dict['pvs'] {
                ret_list.append(property_name);
            }
        }
    }
    return ret_list;
}