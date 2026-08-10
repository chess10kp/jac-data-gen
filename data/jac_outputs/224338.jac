"""Check whether a line is header; if so, convert it to HTML format."""
def check_header(line: str) -> tuple[bool, str] {
    header_id = line.replace(' ', '-');
    if line[:7] == '###### ' {
        line = '<h6 id="' + header_id[7:] + '">' + line[7:] + '</h6>';
    } elif line[:6] == '##### ' {
        line = '<h5 id="' + header_id[6:] + '">' + line[6:] + '</h5>';
    } elif line[:5] == '#### ' {
        line = '<h4 id="' + header_id[5:] + '">' + line[5:] + '</h4>';
    } elif line[:4] == '### ' {
        line = '<h3 id="' + header_id[4:] + '">' + line[4:] + '</h3>';
    } elif line[:3] == '## ' {
        line = '<h2 id="' + header_id[3:] + '">' + line[3:] + '</h2>';
    } elif line[:2] == '# ' {
        line = '<h1 id="' + header_id[2:] + '">' + line[2:] + '</h1>';
    } else {
        return (False, '');
    }
    return (True, line);
}