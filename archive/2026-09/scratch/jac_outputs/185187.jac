"""
    Returns the white matter probability map from the list of segmented probability maps

    Parameters
    ----------

    probability_maps : list (string)
        List of Probability Maps

    Returns
    -------

    file : string
        Path to segment_prob_2.nii.gz is returned

    """
def pick_wm_2(probability_maps: list[str] | str) -> str | None {
    if isinstance(probability_maps, list) {
        if len(probability_maps) == 1 {
            probability_maps = probability_maps[0];
        }
        for filename in probability_maps {
            if filename.endswith("seg_2.nii.gz") {
                return filename;
            }
        }
    }
    return None;
}