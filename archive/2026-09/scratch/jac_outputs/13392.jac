"""Format data as a table """
def _format_data_as_table(data: Any) -> object {
    if isinstance(data, `dict) {
        data = [data];
    }
    common_keys = {
        key
        for (key, val) in data[0].items()
        if isinstance(val, str)
    };
    for idx in range(1, len(data)) {
        common_keys = common_keys.intersection(`set(data[idx].keys()));
    }
    common_keys = sorted(common_keys);
    column_width = {val: len(data[0][val]) for val in common_keys};
    row_format = ''.join(
        [('{:' + str(width) + '}\t\t') for (_, width) in column_width.items()]
    );
    title = row_format.format(*column_width.keys());
    separator_column_width = [('-' * width) for (_, width) in column_width.items()];
    separator = row_format.format(*separator_column_width);
    formatted_data = title + '\n' + separator;
    for `entry in data {
        row_data = [`entry[key] for key in common_keys];
        formatted_data += '\n' + row_format.format(*row_data);
    }
    return formatted_data;
}