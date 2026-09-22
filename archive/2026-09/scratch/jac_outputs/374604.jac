"""Checks if selection is correct."""
def is_valid_selection(ext: str) -> bool {
    formats = [
        'System',
        'Protein',
        'Protein-H',
        'C-alpha',
        'Backbone',
        'MainChain',
        'MainChain+Cb',
        'MainChain+H',
        'SideChain',
        'SideChain-H',
        'Prot-Masses',
        'non-Protein',
        'Water',
        'SOL',
        'non-Water',
        'Ion',
        'NA',
        'CL',
        'Water_and_ions'
    ];
    return ext in formats;
}