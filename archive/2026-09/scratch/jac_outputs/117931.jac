"""Convert the MC Land use classes to the specific things I'm interested in."""
def convert_classes(raw_data: dict[str, list[str]], local_label_dict: dict[str, str]) -> dict[str, list[str]] {
    data: dict[str, list[str]] = {};
    for (label, images) in raw_data.items() {
        local_label = local_label_dict[label];
        if label {
            data[local_label] = images;
        }
    }
    return data;
}