"""removes blank lines and commented lines"""
def clean_lines(lines: Any) -> object {
    lines2 = [];
    for line in lines {
        line2 = line.split('#')[0].strip();
        if line2 {
            lines2.append(line2);
        }
    }
    return lines2;
}