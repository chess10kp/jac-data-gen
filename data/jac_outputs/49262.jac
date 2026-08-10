"""Split a list of lines using empty lines as separators."""
def group_lines(lines: list[str]) -> list[list[str]] {
    groups = [];
    group = [];
    for line in lines {
        if line.strip() == "" {
            groups.append(group[:]);
            group = [];
            continue;
        }
        group.append(line);
    }
    if group {
        groups.append(group[:]);
    }
    return groups;
}