"""Return only the name portion of a Python Dependency Specification string

    the name may still be non-normalized
    """
def clean_requirement(requirement: Any) -> object {
    return requirement.split("=")[0].split("<")[0].split(">")[0].split("~")[0].split(
        "!"
    )[0].split(
        "^"
    )[0].split(
        ";"
    )[0].split(
        "["
    )[0].split(
        "@"
    )[0].strip();
}