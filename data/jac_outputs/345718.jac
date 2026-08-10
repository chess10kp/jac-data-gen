"""Add key value pairs to the output_dict"""
def flat_file_add_to_output_dict(
    output_dict: dict[str, str],
    location_in_json: str,
    data_dict: dict[str, str]
) -> dict[str, str] {
    for (key, value) in data_dict.items() {
        add_command = location_in_json + "[\"" + key + "\"] = " + value;
        try {
            exec(add_command);
        } except (NameError, SyntaxError) {
            add_command = location_in_json + "[\"" + key + "\"] = \"" + value + "\"";
            exec(add_command);
        }
    }
    return output_dict;
}