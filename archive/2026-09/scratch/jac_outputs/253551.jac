"""Convert structure annotation with integer time positions (given in indices)
    into label sequence

    Args:
        ann: Annotation (list  [[s,t,'label'], ...], with s,t being integers)

    Returns:
        X: Sequencs of labels
    """
def convert_ann_to_seq_label(ann: Any) -> object {
    X = [];
    for seg in ann {
        K = seg[1] - seg[0];
        for k in range(K) {
            X.append(seg[2]);
        }
    }
    return X;
}