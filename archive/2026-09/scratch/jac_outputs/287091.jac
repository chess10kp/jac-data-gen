"""Gets data entries from html lines
    """
def getpoint(line: Any) -> object {
    spline = line.split('<tr><td class="xl28b">&nbsp;&nbsp;');
    if (len(spline) > 1) {
        data = spline[1].split('</td></tr>')[0];
    } else {
        data = None;
    }
    return data;
}