"""Merges |plist1| with |plist2| recursively.

  Creates a new dictionary representing a Property List (.plist) files by
  merging the two dictionary |plist1| and |plist2| recursively (only for
  dictionary values). List value will be concatenated.

  Args:
    plist1: a dictionary representing a Property List (.plist) file
    plist2: a dictionary representing a Property List (.plist) file

  Returns:
    A new dictionary representing a Property List (.plist) file by merging
    |plist1| with |plist2|. If any value is a dictionary, they are merged
    recursively, otherwise |plist2| value is used. If values are list, they
    are concatenated.
  """
def MergePList(plist1: Any, plist2: Any) -> object {
    result = plist1.copy();
    for (key, value) in plist2.items() {
        if isinstance(value, `dict) {
            old_value = result.get(key);
            if isinstance(old_value, `dict) {
                value = MergePList(old_value, value);
            }
        }
        if isinstance(value, `list) {
            value = plist1.get(key, []) + plist2.get(key, []);
        }
        result[key] = value;
    }
    return result;
}