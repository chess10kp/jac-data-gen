""" Takes a dict with values in seconds and rounds the values for legibility"""
def format_dictionary_durations(dictionary: dict[str, float]) -> dict[str, int] {
    formatted_dict: dict[str, int] = {};
    for (k, v) in dictionary.items() {
        try {
            formatted_dict[k] = round(v);
        } except TypeError {
            ;
        }
    }
    return formatted_dict;
}