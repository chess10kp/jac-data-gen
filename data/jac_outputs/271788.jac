"""same as formatTypes but for abilities"""
def formatAbilities(abilities: list[dict[str, dict[str, str]]]) -> str {
    res = "";
    for i in range(len(abilities) - 1, -1, -1) {
        res += abilities[i]["ability"]["name"] + ";";
    }
    return res;
}