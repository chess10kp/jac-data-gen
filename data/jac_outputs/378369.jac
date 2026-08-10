"""Check whether the credentials are valid or not."""
def check_config(cred: dict) -> bool {
    for key in cred {
        if cred[key] == "XXXX" {
            return False;
        }
    }
    return True;
}