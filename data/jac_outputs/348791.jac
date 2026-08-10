"""Correct protein names with incorrect separators involving '[Cleaved into: ...]'."""
def correct_protein_name_list(lst: str) -> str {
    if lst {
        lst = lst.replace(
            '[Cleaved into: Nuclear pore complex protein Nup98;',
            '[Cleaved into: Nuclear pore complex protein Nup98];'
        );
        lst = lst.replace('[Cleaved into: Lamin-A/C;', '[Cleaved into: Lamin-A/C];');
        lst = lst.replace('[Cleaved into: Lamin-A/C ;', '[Cleaved into: Lamin-A/C ];');
        lst = lst.replace('[Includes: Maltase ;', '[Includes: Maltase ];');
    }
    return lst;
}