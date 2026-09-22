"""
    put one statement on each line
    """
def unify(lines: list[str]) -> list[str] {
    results = [];
    result = [];
    for line in lines {
        result.append(line);
        if ";" in line {
            results.append("".join(result));
            result = [];
        }
    }
    return results;
}