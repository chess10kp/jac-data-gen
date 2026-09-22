glob LOWER_A = 0x61;
glob LOWER_Z_BOUND = 0x7A;

""" Indicates if the char is lower """
def islower(char: str) -> bool {
    if len(char) == 1 {
        if ord(char) >= LOWER_A and ord(char) < LOWER_Z_BOUND {
            return True;
        }
    }
    return False;
}