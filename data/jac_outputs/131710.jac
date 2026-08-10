"""Given the first pass code, generate any labels"""
def calculate_labels(first_pass: list[tuple[str | None, str]]) -> dict[str, int] {
    address = 0;
    labels = {};
    for (label, instruction) in first_pass {
        if label {
            labels[label] = address;
        }
        address += len(instruction);
    }
    return labels;
}