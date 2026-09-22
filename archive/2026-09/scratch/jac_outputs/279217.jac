"""Return the Excel column number for a column title string."""
def excel_title_to_column(column_title: str) -> int {
    assert column_title.isupper();
    answer = 0;
    index = len(column_title) - 1;
    power = 0;
    while index >= 0 {
        value = (ord(column_title[index]) - 64) * pow(26, power);
        answer += value;
        power += 1;
        index -= 1;
    }
    return answer;
}