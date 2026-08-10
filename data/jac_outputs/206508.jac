"""return URL for ExoMol for isotope
    """
def url_Exomol_iso(molecule: Any, isotope_full_name: Any) -> object {
    url = (
        "https://exomol.com/data/molecules/"
        + str(molecule)
        + "/"
        + str(isotope_full_name)
    );
    return url;
}