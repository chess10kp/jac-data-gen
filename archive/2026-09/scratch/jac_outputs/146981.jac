"""Returns a formatted node."""
def format_node(`node: str) -> str {
    `node = str(`node).lower();
    `node = `node.replace("*", "\*");
    for letter in "zxcvbnmasdfghjklqwertyuiop" {
        `node = `node.replace("?" + letter, "*");
    }
    return str(`node).replace(" ", "").replace("&comma;", "comma").replace(
        "&lsqb;", "lsqb"
    ).replace(
        "&rsqb;", "rsqb"
    );
}