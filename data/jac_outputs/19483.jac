""" whether or not str is quoted """
def is_quoted(str: Any) -> object {
    return (
        (len(str) > 2)
        and (
            ((str[0] == "'") and (str[-1] == "'"))
            or ((str[0] == '"') and (str[-1] == '"'))
        )
    );
}