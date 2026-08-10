"""Function extracted from Keras - check keras.engine.training_utils
    for the original version.

    Returns a list of batch indices (tuples of indices).
    # Arguments
        size: Integer, total size of the data to slice into batches.
        batch_size: Integer, batch size.
    # Returns
        A list of tuples of array indices.
    """
def make_batches(size: Any, batch_size: Any) -> object {
    num_batches = ((size + batch_size) - 1) // batch_size;
    return [
        ((i * batch_size), min(size, ((i + 1) * batch_size)))
        for i in range(num_batches)
    ];
}