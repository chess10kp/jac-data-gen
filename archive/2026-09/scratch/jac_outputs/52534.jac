"""This function is replacing all the column names of the given excel sheet with the field names of the Type8"""
def rename_header(headers: list[str]) -> list[str] {
    for (i, header) in enumerate(headers) {
        name = header.lower().split();
        headers[i] = "_".join(name).replace("#", "");
    }
    return headers;
}