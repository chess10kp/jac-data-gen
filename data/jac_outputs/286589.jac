"""
    Create a list of dictionaries from a whitespace and newline delimited text.

    For example, this:
    cpu 1100
    ram 640

    cpu 2200
    ram 1024

    becomes:
    [{'cpu': '1100', 'ram': '640'}, {'cpu': '2200', 'ram': '1024'}]
    """
def str2dicts(data: str) -> list[dict[str, str]] {
    list_data = [];
    list_data.append({});
    d = list_data[-1];
    for line in data.split('\n') {
        line = line.strip();
        if not line {
            d = {};
            list_data.append(d);
            d = list_data[-1];
            continue;
        }
        whitespace = line.find(' ');
        if not whitespace {
            continue;
        }
        key = line[0:whitespace];
        value = line[(whitespace + 1):];
        d.update({key: value});
    }
    return [val for val in list_data if val != {}];
}