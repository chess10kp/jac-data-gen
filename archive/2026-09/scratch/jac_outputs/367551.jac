"""Turn a string into a positive integer."""
def string_to_int(string: str, keyspace_chars: str) -> int {
    output = 0;
    for char in string {
        output = output * len(keyspace_chars) + keyspace_chars.index(char);
    }
    return output;
}