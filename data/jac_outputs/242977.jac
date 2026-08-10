"""
Checks to make sure input JSON is valid and contains the appropriate keys.
Will also check to make sure the number of dates passed in matches the number
of readings.

Returns True if all checks passed, False otherwise.
"""
def valid_heart_json(input_json: dict) -> bool {
    if isinstance(input_json, dict)
        and 'hrDates' in input_json
        and 'hrValues' in input_json
        and len(input_json['hrDates']) == len(input_json['hrValues']) {
        return True;
    }
    print(
        "The JSON file passed in is missing data -- please check the output from Shortcuts."
    );
    return False;
}