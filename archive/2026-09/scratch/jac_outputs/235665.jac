""":param n: decimal number to be converted to trinary. :returns: trinary string of the number n."""
def dec_to_tri(n: int) -> str {
    tri_string = "";
    while n != 0 {
        tri_string = str(n % 3) + tri_string;
        n = n // 3;
    }
    return tri_string;
}