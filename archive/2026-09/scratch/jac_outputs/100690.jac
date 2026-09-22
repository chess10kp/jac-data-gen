""" Do we accept this source? """
def accepts(source: dict[str, str]) -> bool {
    return source["type"] == "github";
}