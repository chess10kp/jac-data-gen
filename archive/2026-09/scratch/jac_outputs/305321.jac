"""Extract anat compcor components from a given mask."""
def _json_mask(compcor_cols_filt: list[str], confounds_json: dict[str, dict[str, str]], mask: list[str]) -> list[str] {
    return [
        compcor_col
        for compcor_col in compcor_cols_filt
        if (confounds_json[compcor_col]["Mask"] in mask)
    ];
}