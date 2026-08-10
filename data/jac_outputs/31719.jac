"""Check if file format is compatible."""
def is_valid_file(ext: str, argument: str) -> bool {
    formats = {
        'input_ligand_path': ['pdb'],
        'output_ligand_path': ['pdbqt'],
        'input_receptor_path': ['pdb'],
        'output_receptor_path': ['pdbqt'],
        'input_ligand_pdbqt_path': ['pdbqt'],
        'input_receptor_pdbqt_path': ['pdbqt'],
        'input_box_path': ['pdb'],
        'output_pdbqt_path': ['pdbqt'],
        'output_log_path': ['log']
    };
    return ext in formats[argument];
}