"""Project vector onto different basis."""
def project_onto_basis(
    x: float,
    y: float,
    z: float,
    xx: float,
    xy: float,
    xz: float,
    yx: float,
    yy: float,
    yz: float,
    zx: float,
    zy: float,
    zz: float
) -> tuple[float, float, float] {
    out_x = x * xx + y * xy + z * xz;
    out_y = x * yx + y * yy + z * yz;
    out_z = x * zx + y * zy + z * zz;
    return (out_x, out_y, out_z);
}