"""Turn a UCSC DCC files.txt index into a dictionary of name-value pairs."""
def parse_ucsc_file_index(stream: list[str], base_url: str) -> dict[str, dict[str, str]] {
    file_index = {};
    for line in stream {
        (filename, attribute_line) = line.split('\t');
        filename = base_url + filename;
        attributes = {};
        for assignment in attribute_line.split(';') {
            (name, value) = assignment.split('=');
            attributes[name.strip()] = value.strip();
        }
        file_index[filename] = attributes;
    }
    return file_index;
}