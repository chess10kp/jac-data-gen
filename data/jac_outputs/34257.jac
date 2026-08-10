"""To change the input data from string to integer

    This function will take the input data with keys "patient id"
    and "patient age" and change them from string to integer.
    If it contains more than integer it will show an error message.

    :param in_data: JSON contains keys "patient id" and "patient age"
    :return: the changed data format (to int) or error message
    """
def parse_new_patient(in_data: Any) -> object {
    if (`type(in_data) is not `dict) {
        return "No dictionary exists";
    }
    if ("patient_id" in in_data.keys()) {
        try {
            in_data["patient_id"] = int(in_data["patient_id"]);
        } except ValueError {
            return "Patient ID is not a number or can't convert to integer";
        }
    } else {
        return "No such key: patient_id";
    }
    if ("patient_age" in in_data.keys()) {
        try {
            in_data["patient_age"] = int(in_data["patient_age"]);
        } except ValueError {
            return "Patient age is not a number or can't convert to integer";
        }
    } else {
        return "No such key: patient_age";
    }
    return in_data;
}