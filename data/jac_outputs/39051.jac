"""Convert an input description into command line argument."""
def nf_input_to_cl(inp: dict[str, str | bool]) -> str {
    sep = " " if inp.get("separate") else "";
    val = "'%s'" % inp.get("default") if inp.get("default") else "$%s" % inp["name"];
    return "%s%s%s" % (inp["prefix"], sep, val);
}