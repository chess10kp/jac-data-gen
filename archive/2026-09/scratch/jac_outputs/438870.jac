"""Checks which formatting keys are present in a given string"""
def _key_in_string(string: Any, string_formatting_dict: Any) -> object {
    key_in_string = False;
    if isinstance(string, str) {
        for (key, value) in string_formatting_dict.items() {
            if (("{" + key + "}") in string) {
                key_in_string = True;
            }
        }
    }
    return key_in_string;
}