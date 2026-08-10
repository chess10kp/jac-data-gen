"""Convert a label name used in j2cl to be used in j2kt native."""
def _to_j2kt_native_name(name: str) -> str {
    if name.endswith("-j2cl") {
        name = name[:-5];
    }
    return "%s-j2kt-native" % name;
}