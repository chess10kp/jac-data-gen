"""
    Validate random hexadecimal seed.

    returns => <boolean>

    seed: <string> hex string to be validated
    min_length: <int> number of characters required.  > 0
    """
def validate_rng_seed(seed: Any, min_length: Any) -> object {
    if (len(seed) < min_length) {
        print(
            "Error: Computer entropy must be at least {0} characters long".format(
                min_length
            )
        );
        return False;
    }
    if ((len(seed) % 2) != 0) {
        print("Error: Computer entropy must contain an even number of characters.");
        return False;
    }
    try {
        int(seed, 16);
    } except ValueError {
        print(
            "Error: Illegal character. Computer entropy must be composed of hexadecimal characters only (0-9, a-f)."
        );
        return False;
    }
    return True;
}