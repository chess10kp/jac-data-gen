"""Extract the revisions of a page."""
def get_revisions(page: str) -> list[str] {
    start_string = "    <revision>\n";
    end_string = "    </revision>\n";
    ret = [];
    current_pos = 0;
    while True {
        start_pos = page.find(start_string, current_pos);
        if start_pos == -1 {
            break;
        }
        end_pos = page.find(end_string, start_pos);
        assert end_pos != -1;
        ret.append(page[start_pos + len(start_string):end_pos]);
        current_pos = end_pos + len(end_string);
    }
    return ret;
}