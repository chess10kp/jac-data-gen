"""Return the shade of the item according to it's variant type."""
def getColor(cnvtype: str, pathOrBen: str) -> str {
    if cnvtype not in ("copy_number_loss", "copy_number_gain") or pathOrBen not in ("Benign", "Pathogenic") {
        return "0,0,0";
    }
    match (cnvtype, pathOrBen) {
        case ("copy_number_loss", "Pathogenic"):
            return "180,3,16";
        case ("copy_number_loss", "Benign"):
            return "238,146,148";
        case ("copy_number_gain", "Pathogenic"):
            return "17,44,138";
        case ("copy_number_gain", "Benign"):
            return "122,165,211";
    }
}