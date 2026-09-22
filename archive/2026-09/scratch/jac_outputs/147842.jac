"""Allow a frequency of type [float] to be compared with =="""
def freq_to_compare(f: Any) -> object {
    f = int(round(f));
    return f;
}