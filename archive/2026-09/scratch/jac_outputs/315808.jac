"""
    Returns :samp:`sequence` :obj:`list` end-padded with :samp:`{obj}`
    elements so that the length of the returned list equals :samp:`{new_length}`.

    :type sequence: iterable
    :param sequence: Return *listified* sequence which has been end-padded.
    :type new_length: :obj:`int`
    :param new_length: The length of the returned list.
    :type obj: :obj:`object`
    :param obj: Object used as padding elements.
    :rtype: :obj:`list`
    :return: A :obj:`list` of length :samp:`{new_length}`.
    :raises ValueError: if :samp:`len({sequence}) > {new_length})`.

    Example::

       >>> pad_with_object([1, 2, 3], 5, obj=0)
       [1, 2, 3, 0, 0]
       >>> pad_with_object([1, 2, 3], 5, obj=None)
       [1, 2, 3, None, None]

    """
def pad_with_object(sequence: Any, new_length: Any, `obj: Any = None) -> object {
    if (len(sequence) < new_length) {
        sequence = `list(sequence) + ([`obj] * (new_length - len(sequence)));
    } elif (len(sequence) > new_length) {
        raise ValueError(
            (
                "Got len(sequence)=%s which exceeds new_length=%s"
                % (len(sequence), new_length)
            )
        );
    }
    return sequence;
}