"""Checks if file format is compatible."""
def is_valid_file(ext: str, argument: str) -> bool {
    formats = {
        'input_pdb_path': ['pdb', 'pqr'],
        'input_clusters_zip': ['zip'],
        'resid_pdb_path': ['pdb'],
        'input_pdbqt_path': ['pdbqt'],
        'output_pdb_path': ['pdb'],
        'output_pdbqt_path': ['pdbqt']
    };
    return ext in formats[argument];
}