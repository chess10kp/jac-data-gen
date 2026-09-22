import re;

"""Return True for a valid username, or an error message if it contains digits."""
def str_username(attending_username: str) -> bool | str {
    if bool(re.search(r'\d', attending_username)) is False {
        return True;
    }
    return "Please enter a valid username string with no numbers!";
}