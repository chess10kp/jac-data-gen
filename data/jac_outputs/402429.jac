"""reprFloat(float) -> string

Return the string representation of an IDL float type (float, double,
long double), with enough precision to completely reconstruct the bit
pattern."""
def reprFloat(f: float) -> str {
    s = "%.17g" % f;
    if s.find(".") == -1 and s.find("e") == -1 {
        s = s + ".0";
    }
    return s;
}