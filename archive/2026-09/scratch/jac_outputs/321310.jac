"""Validates the inputs of the incoming dictionary.

This function receives a dictionary as input. Within this
dictionary are a patient's medical record number as well
as a specific file name for that patient. This function
checks to ensure that the medical record number is an int
and checks to ensure that the file name is a string. If
these are not the case, it will inform the user. Otherwise,
it will return True."""
def validate_medical_image_specific(in_dict: dict[str, int | str]) -> bool | str {
    my_keys = list(in_dict.keys());
    for key in my_keys {
        if key == "patient" {
            if isinstance(in_dict[key], int) {
                continue;
            } else {
                return "A valid patient id was not provided, try again";
            }
        }
        if key == "file_name" {
            if isinstance(in_dict[key], str) {
                continue;
            } else {
                return "A valid filename was not provided, try again";
            }
        } else {
            return "The input dictionary has unusable information, try again";
        }
    }
    return True;
}