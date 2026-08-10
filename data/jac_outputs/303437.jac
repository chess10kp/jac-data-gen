""" Returns the integer in the filename 'filen'. For example,
    for 'image_13.npy', this function returns 13 as an integer
    """
def y(filen: str) -> int {
    cname = '';
    for c in filen {
        if c.isdigit() {
            cname += c;
        }
    }
    return int(cname);
}