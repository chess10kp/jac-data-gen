"""Wrapper for the ``tbss_non_FA`` command.
    e.g.: ``tbss_non_FA("L2")``
    """
def non_FA(alt_img_root: str) -> list[str] {
    return ["tbss_non_FA", alt_img_root];
}