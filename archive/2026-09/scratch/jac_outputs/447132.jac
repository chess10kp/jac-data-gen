"""
    B - batch
    S - sequence
    F - features
    :param d: torch.Tensor or np.ndarray of shape specified below
    :param is_seq: True if d has sequence dim
    :return: axis of features
    """
def features_axis_is_np(is_np: Any, is_seq: Any = False) -> object {
    if is_np {
        return (0 + is_seq);
    } else {
        return (1 + is_seq);
    }
}