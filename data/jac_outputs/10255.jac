"""
Selects the chromosomes you want to overlap.
A(autosomes), AS (Auto+Sex), or ASM (Auto+Sex+M).
"""
def pickChromosomes(selection: str = 'A') -> list[str] {
    chr_list = [
        '1', '2', '3', '4', '5',
        '6', '7', '8', '9', '10',
        '11', '12', '13', '14', '15',
        '16', '17', '18', '19', '20',
        '21', '22'
    ];
    if selection in ("AS", "ASM") {
        chr_list.append("x");
        chr_list.append("y");
    }
    if selection == "ASM" {
        chr_list.append("m");
    }
    return chr_list;
}