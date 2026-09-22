"""Generate an image name from image coordinates."""
def _get_image_name(
    base_name: str,
    row: int,
    col: int,
    Z: int | None = None,
    C: int | None = None,
    T: int | None = None,
    padding: int = 3
) -> str {
    name = base_name;
    name += "_y" + str(row).zfill(padding);
    name += "_x" + str(col).zfill(padding);
    if Z is not None {
        name += "_z" + str(Z).zfill(padding);
    }
    if C is not None {
        name += "_c" + str(C).zfill(padding);
    }
    if T is not None {
        name += "_t" + str(T).zfill(padding);
    }
    name += ".ome.tif";
    return name;
}