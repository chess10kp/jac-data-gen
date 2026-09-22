"""Format field labels and values."""
def format_fields(field_data: list[tuple[str, str | int | None]], include_empty: bool = True) -> str {
    max_label = 0;
    for (label, value) in field_data {
        label_length = len(label);
        if label_length > max_label {
            max_label = label_length;
        }
    }
    fields = [];
    for (label, value) in field_data {
        empty = str(value).strip() in ['', 'None'];
        if not empty or include_empty {
            label_length = len(label.strip());
            extra_spaces = ' ' * (max_label - label_length);
            label_sep = ':' + extra_spaces + ' ';
            joined_field = label_sep.join([label, str(value)]);
            fields.append(joined_field);
        }
    }
    return '\n'.join(fields);
}