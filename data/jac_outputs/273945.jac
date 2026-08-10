"""
    This function is used to concat a string of words by putting underscore between words
    example: "new york steuben" --> "new_york_steuben"
    """
def concat_name_county(name: str | int | float) -> str {
    try {
        assert name != "";
    } except AssertionError as exp {
        exp.args += (
            'input must not be a empty string',
            "check concat_name_county function"
        );
        raise;
    }
    name_vector = str(name).split(" ");
    concat_name = "";
    for word in name_vector {
        if word in [" ", ""] {
            continue;
        } else {
            concat_name = concat_name + "_" + str(word);
        }
    }
    return concat_name[1:].strip();
}