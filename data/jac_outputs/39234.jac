"""Returns the string sentence-cased in an 05AB1E manner."""
def sentence_case(item: str) -> str {
    ret = "";
    capitalise = True;
    for char in item {
        ret += char.upper() if capitalise else char.lower();
        if capitalise and char != " " {
            capitalise = False;
        }
        capitalise = capitalise or char in "!?.";
    }
    return ret;
}