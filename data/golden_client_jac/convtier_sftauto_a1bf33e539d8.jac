def bytes_to_kilobytes(`bytes: Any) -> object {
    return (`bytes >> 10);
}



with entry {
    print(bytes_to_kilobytes(5));
}
