"""ImageJ uses tag 50838 to indicate size of metadata elements (e.g., 768 bytes per ROI)."""
def ij_tag_50838(nchannels: int) -> tuple[int, ...] {
    info_block = (20,);
    display_block = (16 * nchannels,);
    luts_block = (256 * 3,) * nchannels;
    return info_block + display_block + luts_block;
}