"""Adjust linebreaks to match ';', strip leading/trailing whitespace.

Lines are adjusted so that no linebreaks occur within a commandline
(except matrix command line).
"""
def _adjust_lines(lines: list[str]) -> list[str] {
    formatted_lines = [];
    for line in lines {
        line = line.replace('\r\n', '\n').replace('\r', '\n').strip();
        if line.lower().startswith('matrix') {
            formatted_lines.append(line);
        } else {
            line = line.replace('\n', ' ');
            if line {
                formatted_lines.append(line);
            }
        }
    }
    return formatted_lines;
}