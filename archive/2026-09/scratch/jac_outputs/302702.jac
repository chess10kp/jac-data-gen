""" Find valid passwords with min and max count """
def validate_passwords(password_list: Any) -> object {
    count = 0;
    for password in password_list {
        if (
            password["min"]
            <= password["password"].count(password["char"])
            <= password["max"]
        ) {
            count += 1;
        }
    }
    return count;
}