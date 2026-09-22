glob PIECE_SIZE_1GB = 2 ** 19;
glob PIECE_SIZE_500MB = 2 ** 18;
glob PIECE_SIZE_250MB = 2 ** 17;
glob PIECE_SIZE_125MB = 2 ** 16;
glob PIECE_SIZE_63MB = 2 ** 15;
glob PIECE_SIZE_DEFAULT = 2 ** 14;

"""Based on the size of the file, we decide the size of the pieces."""
def piece_size(file_size: int) -> int {
    if file_size >= 1000 {
        return PIECE_SIZE_1GB;
    } elif file_size >= 500 {
        return PIECE_SIZE_500MB;
    } elif file_size >= 250 {
        return PIECE_SIZE_250MB;
    } elif file_size >= 125 {
        return PIECE_SIZE_125MB;
    } elif file_size >= 63 {
        return PIECE_SIZE_63MB;
    } else {
        return PIECE_SIZE_DEFAULT;
    }
}