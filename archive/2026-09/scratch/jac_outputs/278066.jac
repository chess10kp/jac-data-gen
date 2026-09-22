"""This is currently the best way of telling if an object is an openscap XCCDF benchmark object."""
def is_xccdf(`obj: object) -> bool {
    try {
        return getattr(`obj, "object") == "xccdf_benchmark";
    } except Exception {
        return False;
    }
}