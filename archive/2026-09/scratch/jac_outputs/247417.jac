"""turn a primer dict from primer3 in fastCloningPrimer to the NEB readdable format"""
def primerDictToNEBPrimerSeq(primerDict: dict[str | int, list[list[str]]]) -> str {
    neb_primer_string = "";
    for (primer_pair_name, primer_pair_info) in primerDict.items() {
        left_name = str(primer_pair_name) + "Left";
        left_seq = primer_pair_info[0][2];
        right_name = str(primer_pair_name) + "Right";
        right_seq = primer_pair_info[1][2];
        neb_primer_string += left_name + "; " + left_seq + "; " + right_name + "; " + right_seq + "\n";
    }
    return neb_primer_string;
}