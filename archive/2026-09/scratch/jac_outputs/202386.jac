"""Return the number of bytes used by a varint type."""
def varint_type_to_length(varint: int) -> tuple[int, int | str] {
    match varint {
        case 5:
            return (6, "");
        case 6:
            return (8, "");
        case 7:
            return (8, "");
        case 8:
            return (0, 0);
        case 9:
            return (0, 1);
        case _:
            return (varint, "");
    }
}