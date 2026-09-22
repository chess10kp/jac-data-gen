"""Validate the passed options for capturing output."""
def _capture_callback(x: str | None) -> str | None {
    if x in [None, "None", "none"] {
        x = None;
    } elif x in ["fd", "no", "sys", "tee-sys"] {
        ;
    } else {
        raise ValueError(
            "'capture' can only be one of ['fd', 'no', 'sys', 'tee-sys']."
        );
    }
    return x;
}