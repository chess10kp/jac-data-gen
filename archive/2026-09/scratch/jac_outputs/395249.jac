"""Returns a dictionary where keys are bazel label objects and values are strings.

    Bazel does not currently support a dictionary attr where keys are strings
    and values are a list of labels.

    Example:
    {"-y": [":abc", ":def"], "-x": [":abc"]} --> {":abc": "-x -y", ":def": "-y"}
    """
def invert_label_keyed_string_dict(dictionary: dict[str, list[str]]) -> dict[str, str] {
    result: dict[str, str] = {};
    for (key, val) in dictionary.items() {
        for label in val {
            if label in result {
                result[label] += " {}".format(key);
            } else {
                result[label] = key;
            }
        }
    }
    return result;
}