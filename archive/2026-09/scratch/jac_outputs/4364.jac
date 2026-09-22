""" Take any number of string args and put them together as a
    HTML table row.
    """
def table_append(row: list[str], category: str = 'default') -> str {
    html_row = '</td><td>'.join(row);
    html_row = f'<tr><td>{html_row}</td></tr>';
    if category == 'header' {
        html_row = html_row.replace('td>', 'th>');
    }
    return html_row;
}