"""Generate CSV headers: fixed supplier columns plus numbered question ids."""
def headers(questions: list[str]) -> list[str] {
    csv_headers = [
        'Digital Marketplace ID',
        'Digital Marketplace Name',
        'Digital Marketplace Duns number',
        'State of Declaration'
    ];
    for (index, value) in enumerate(questions) {
        csv_headers.append(f"{index + 1}:{value}");
    }
    return csv_headers;
}