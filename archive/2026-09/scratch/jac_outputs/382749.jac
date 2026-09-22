"""

    Parameters
    ----------
    inp Input string

    Returns A list of pi expressions
    -------

    """
def str_to_pi_list(inp: Any) -> object {
    lines = inp.strip().splitlines();
    lis = [];
    for line in lines {
        if (line == "None") {
            return [];
        }
        lis.append(line);
    }
    return lis;
}