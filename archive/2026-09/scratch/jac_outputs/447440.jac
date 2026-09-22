"""Adds encountered keyerrors into one concatenated string."""
def add_up_errors(list_keyerror: list[str | None]) -> str | None {
    keyerror = '';
    for key in list_keyerror {
        if len(keyerror) > 0 and key is not None {
            keyerror += " ; ";
        }
        if key is not None {
            keyerror += str(key);
        }
    }
    if keyerror == '' {
        return None;
    }
    return keyerror;
}