"""Determine mesh output format from a filename extension."""
def _mesh_export_format_from_filename(filename: str) -> tuple[str, bool] {
    if filename.endswith('.ply') {
        return ('ply', True);
    } elif filename.endswith('.obj') {
        return ('obj', True);
    } else {
        return ('obj', False);
    }
}