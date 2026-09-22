"""
    Generates an initial job sequence based on the first-in-first-out
    dispatching strategy. The job sequence will be feed to the model.
    """
def fifo_pre_sequencing(dataset: Any, *args: Any, **kwargs: Any) -> object {
    sequence = [job for job in dataset.values()];
    return sequence;
}