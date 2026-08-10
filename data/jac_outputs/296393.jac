"""Returns filename given a dictionary with name components."""
def build_filename(fname: dict[str, str]) -> str {
    filename = fname["name"];
    assert "out_src" in fname, "Named_dict (fname) does not contain 'out' keys.";
    filename = (
        filename
        + "."
        + fname["out_src"]
        + "-"
        + fname["out_tgt"]
        + "."
        + fname["out_ext"]
    );
    return filename;
}