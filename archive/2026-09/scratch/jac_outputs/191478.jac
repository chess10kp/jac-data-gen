"""strings stored in an HDF5 from Python2 may look like
     "b'xxx'", that is containg "b".  strip these out here
    """
def h5str(`obj: str | bytes) -> str {
    out = str(`obj);
    if out.startswith("b'") and out.endswith("'") {
        out = out[2:-1];
    }
    return out;
}