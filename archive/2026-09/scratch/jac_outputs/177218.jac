"""Byte offset in file where spectrum should occur. spectrum_index begins at 1."""
def _spectrum_byte_offset(
    spectrum_index: int,
    n_records_per_spectrum: int,
    spec_rec_start_index: int = 83
) -> int {
    256 * (spec_rec_start_index + n_records_per_spectrum * (spectrum_index - 1) - 1)
}