"""
Takes a string and breaks it into lines with <= n characters per line.

Useful because psql queries have to have < 212 chars per line.
"""
def cut_lines_to_n(string: str, n: int = 200) -> str {
    out = [];
    lines = string.split("\n");
    for line in lines {
        newline = "";
        for word in line.split(" ") {
            if len(newline + word) + 1 > n {
                out.append(newline.strip());
                newline = word;
            } else {
                newline += " " + word;
            }
        }
        out.append(newline);
    }
    return "\n".join(out);
}