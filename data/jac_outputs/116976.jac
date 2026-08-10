"""
    For some reason Prodigy was assigning the same hashes
    to every example in the data, which meant that when
    it looked at the saved annotations in the dataset to
    figure out which to exclude, it excluded all of them.

    Setting the _input_hash to the index of the candidate
    connection also makes lookup easier when we filter the
    candidates according to their annotation.
    """
def set_hashes(task: dict[str, int | str], i: int) -> dict[str, int | str] {
    task["_input_hash"] = i;
    task["_task_hash"] = -(i + 1);
    return task;
}