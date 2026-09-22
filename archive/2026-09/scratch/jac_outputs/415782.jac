"""Validate heart-rate JSON input and return an error tuple or success status."""
def validate_heart_rate_timestamp(
    in_heart_rate: dict[str, int | str],
    heart_rate_expected_keys: dict[str, type]
) -> tuple[str | bool, int] {
    if type(in_heart_rate) is not dict {
        return ("The input was not a dictionary", 400);
    }
    for key in heart_rate_expected_keys {
        if key not in in_heart_rate {
            return ("The key {} is missing from input".format(key), 400);
        }
        if type(in_heart_rate[key]) is not heart_rate_expected_keys[key] {
            try {
                in_heart_rate[key] = int(in_heart_rate[key]);
            } except ValueError {
                return ("The key {} has the wrong data type".format(key), 400);
            }
        }
    }
    return (True, 200);
}