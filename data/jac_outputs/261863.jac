"""Map Abaqus elment type to meshio types.

    Parameters
    ----------
    element_type : str
        Abaqus element type (e.g C3D8R)

    Returns
    -------
    str
        Meshio element type (e.g. hexahedron)

    """
def abaqus_to_meshio_type(element_type: Any) -> object {
    if (("T2D2" in element_type) or ("T3D2" in element_type)) {
        return "line";
    }
    if (("T2D3" in element_type) or ("T3D3" in element_type)) {
        return "line3";
    }
    if (("B21" in element_type) or ("B31" in element_type)) {
        return "line";
    }
    if (
        ("B22" in element_type) or ("B32" in element_type) or ("B33" in element_type)
    ) {
        return "line3";
    }
    if (("S4" in element_type) or ("R3D4" in element_type)) {
        return "quad";
    }
    if ("S8" in element_type) {
        return "quad8";
    }
    if ("S8" in element_type) {
        return "quad9";
    }
    if (
        ("S3" in element_type) or ("M3D3" in element_type) or ("R3D3" in element_type)
    ) {
        return "triangle";
    }
    if ("STRIA6" in element_type) {
        return "triangle6";
    }
    if (
        ("C3D8" in element_type) or ("EC3D8" in element_type) or ("SC8" in element_type)
    ) {
        return "hexahedron";
    }
    if ("C3D20" in element_type) {
        return "hexahedron20";
    }
    if ("C3D4" in element_type) {
        return "tetra";
    }
    if ("C3D4H" in element_type) {
        return "tetra4";
    }
    if ("C3D10" in element_type) {
        return "tetra10";
    }
    if ("C3D6" in element_type) {
        return "wedge";
    }
}