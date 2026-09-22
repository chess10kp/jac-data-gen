"""code_size - bits per code, maximum length of string_table
    char_size - how many bits for a character (ie, 256 for ascii)"""
def init_table(code_size: int, char_size: int) -> list[list[int] | str] {
    string_table: list[list[int] | str] = [[i] for i in range(char_size)];
    string_table.append("CLEAR");
    string_table.append("END");
    return string_table;
}