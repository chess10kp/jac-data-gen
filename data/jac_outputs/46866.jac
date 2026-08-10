"""Return the Student version Environment Variable name based on an input version string

    Parameters
    ----------
    input_version : str


    Returns
    -------
    str

    Examples
    --------
    >>> env_value_student("2021.1")
    "ANSYSEMSV_ROOT211"
    """
def env_value_student(input_version: str) -> str {
    version = int(input_version[2:4]);
    release = int(input_version[5]);
    if version < 20 {
        if release < 3 {
            version -= 1;
        } else {
            release -= 2;
        }
    }
    v_key = "ANSYSEMSV_ROOT{0}{1}".format(version, release);
    return v_key;
}